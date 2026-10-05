if(!('GptWidgetHostFollower' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

// Keep movement in the native event callback. Calling PowerShell or waiting for
// a DispatcherTimer here makes a separate transparent window trail its host.
public sealed class GptWidgetHostFollower : IDisposable {
 [StructLayout(LayoutKind.Sequential)] struct Rect {public int Left,Top,Right,Bottom;}
 delegate void WinEventProc(IntPtr hook,uint ev,IntPtr hwnd,int objectId,int childId,uint threadId,uint time);
 [DllImport("user32.dll")] static extern IntPtr SetWinEventHook(uint first,uint last,IntPtr module,WinEventProc callback,uint processId,uint threadId,uint flags);
 [DllImport("user32.dll")] static extern bool UnhookWinEvent(IntPtr hook);
 [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h,out Rect r);
 [DllImport("user32.dll")] static extern bool IsWindow(IntPtr h);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h,IntPtr after,int x,int y,int w,int z,uint flags);
 [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h,int command);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint processId);
 [DllImport("user32.dll")] static extern int SetWindowRgn(IntPtr h,IntPtr region,bool redraw);
 [DllImport("gdi32.dll")] static extern IntPtr CreateRectRgn(int left,int top,int right,int bottom);
 [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr value);
 readonly IntPtr widget;
 readonly WinEventProc callback;
 IntPtr host,locationHook,lifecycleHook;
 int insetLeft,insetTop,insetRight,insetBottom,width,height,left,right,bottom;
 int hostWidth,hostHeight,clipWidth=-1,clipHeight=-1;
 string anchor;
 bool enabled,hiddenByHost,disposed;
 public long MovementEvents {get;private set;}
 public long PositionChanges {get;private set;}
 public uint MaxDeliveryMs {get;private set;}
 public uint LastDeliveryMs {get;private set;}
 public bool LayoutDirty {get;private set;}
 public Action LayoutRequested;
 public bool Moving {get;private set;}
 public bool Ready {get{return locationHook!=IntPtr.Zero;}}
 public GptWidgetHostFollower(IntPtr widget){this.widget=widget;callback=OnEvent;}

 public void Configure(IntPtr host,int frameLeft,int frameTop,int frameRight,int frameBottom,
                       int width,int height,int left,int right,int bottom,string anchor,bool enabled){
  if(disposed)return;
  bool changedHost=this.host!=host;
  if(changedHost){
   ReleaseHooks();this.host=host;Moving=false;hiddenByHost=false;
   if(IsWindow(host)){
    uint processId;GetWindowThreadProcessId(host,out processId);
    locationHook=SetWinEventHook(0x800B,0x800B,IntPtr.Zero,callback,processId,0,0);
    lifecycleHook=SetWinEventHook(0x10,0x17,IntPtr.Zero,callback,processId,0,0);
   }
  }
  Rect r;
  if(GetWindowRect(host,out r)){
   if(changedHost||!Moving){
    // Reject a mixed snapshot if the host moved between the frame and HWND reads.
    int il=frameLeft-r.Left,it=frameTop-r.Top,ir=r.Right-frameRight,ib=r.Bottom-frameBottom;
    if(il>=0&&il<=32&&it>=0&&it<=32&&ir>=0&&ir<=32&&ib>=0&&ib<=32){
     insetLeft=il;insetTop=it;insetRight=ir;insetBottom=ib;
    }
   }
   hostWidth=r.Right-r.Left;hostHeight=r.Bottom-r.Top;LayoutDirty=false;
  }
  this.width=width;this.height=height;this.left=left;this.right=right;
  this.bottom=bottom;this.anchor=anchor;this.enabled=enabled;
  if(enabled)Synchronize();
 }
 public void Suspend(){enabled=false;}
 void OnEvent(IntPtr hook,uint ev,IntPtr hwnd,int objectId,int childId,uint threadId,uint time){
  if(disposed||hwnd!=host||objectId!=0||childId!=0)return;
  if(ev==0x10)Moving=true;
  if(ev==0x11)Moving=false;
  if(ev==0x800B){
   MovementEvents++;
   uint delay=unchecked((uint)Environment.TickCount-time);LastDeliveryMs=delay;
   if(delay>MaxDeliveryMs)MaxDeliveryMs=delay;
  }
  Synchronize();
 }
 public bool Synchronize(){
  if(disposed||!enabled||!IsWindow(host)||!IsWindow(widget))return false;
  if(!IsWindowVisible(host)||IsIconic(host)){
   ShowWindow(widget,0);hiddenByHost=true;return false;
  }
  Rect frame,current;if(!GetWindowRect(host,out frame))return false;
  if(!LayoutDirty&&(frame.Right-frame.Left!=hostWidth||frame.Bottom-frame.Top!=hostHeight)){
   LayoutDirty=true;if(LayoutRequested!=null)LayoutRequested();
  }
  frame.Left+=insetLeft;frame.Top+=insetTop;frame.Right-=insetRight;frame.Bottom-=insetBottom;
  int x=anchor=="right"?frame.Right-width-right:frame.Left+left;
  x=Math.Max(frame.Left,Math.Min(frame.Right-width,x));
  int y=Math.Max(frame.Top,frame.Bottom-height-bottom);
  int cw=Math.Max(0,Math.Min(width,frame.Right-x)),ch=Math.Max(0,Math.Min(height,frame.Bottom-y));
  if(cw!=clipWidth||ch!=clipHeight){
   IntPtr region=CreateRectRgn(0,0,cw,ch);
   if(region!=IntPtr.Zero){
    if(SetWindowRgn(widget,region,true)!=0){clipWidth=cw;clipHeight=ch;}
    else DeleteObject(region);
   }
  }
  if(!GetWindowRect(widget,out current)||current.Left!=x||current.Top!=y){
   // Position only: WPF owns size and rendering. No resize, activation or
   // z-order changes, and no queued asynchronous SetWindowPos operation.
   if(!SetWindowPos(widget,IntPtr.Zero,x,y,0,0,0x15))return false;
   PositionChanges++;
  }
  if(hiddenByHost){ShowWindow(widget,4);hiddenByHost=false;}
  return true;
 }
 void ReleaseHooks(){
  if(locationHook!=IntPtr.Zero){UnhookWinEvent(locationHook);locationHook=IntPtr.Zero;}
  if(lifecycleHook!=IntPtr.Zero){UnhookWinEvent(lifecycleHook);lifecycleHook=IntPtr.Zero;}
 }
 public void Dispose(){if(disposed)return;disposed=true;enabled=false;ReleaseHooks();GC.KeepAlive(callback);}
}
'@
}
