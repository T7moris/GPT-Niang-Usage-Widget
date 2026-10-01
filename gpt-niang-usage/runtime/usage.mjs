import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
import readline from 'node:readline';
import {pluginVersion} from './metadata.mjs';

export function normalizeLimits(result, now=Date.now()) {
  const limit = result?.rateLimitsByLimitId ? result.rateLimitsByLimitId.codex : result?.rateLimits;
  const windows = [];
  for (const key of ['primary','secondary']) {
    const raw = limit?.[key];
    const mins = raw?.windowDurationMins;
    const used = raw?.usedPercent;
    const reset = raw?.resetsAt;
    if (![300,10080].includes(mins) || typeof used !== 'number' || !Number.isFinite(used) || used<0 || used>100) continue;
    if (typeof reset !== 'number' || !Number.isFinite(reset) || reset<=0) continue;
    windows.push({label:mins===300?'5 小时':'每周',minutes:mins,used,remaining:100-used,resetsAt:reset});
  }
  windows.sort((a,b)=>a.minutes-b.minutes);
  return {ok:windows.length>0,source:'official',observedAt:now,plan:typeof limit?.planType==='string'?limit.planType:null,windows};
}

// Only three read-only protocol methods are sent. There is no thread or model call.
export function readUsage(cli, {timeoutMs=18000,spawnProcess=spawn}={}) {
  return new Promise(resolve=>{
    let finished=false, proc, pending='';
    const finish=data=>{
      if(finished)return; finished=true; clearTimeout(timer);
      try{proc?.stdin.end();proc?.kill();}catch{}
      resolve(data);
    };
    const timer=setTimeout(()=>finish({ok:false,error:'查询超时，稍后重试',windows:[]}),timeoutMs);
    try{proc=spawnProcess(cli,['app-server','--stdio'],{windowsHide:true,stdio:['pipe','pipe','pipe']});}
    catch{finish({ok:false,error:'Codex 额度服务暂不可用',windows:[]});return;}
    proc.stderr.on('data',()=>{});
    proc.on('error',()=>finish({ok:false,error:'无法启动 Codex 额度服务',windows:[]}));
    proc.on('exit',()=>finish({ok:false,error:'Codex 额度服务已结束',windows:[]}));
    proc.stdin.on('error',()=>finish({ok:false,error:'Codex 额度连接已结束',windows:[]}));
    const send=data=>{try{proc.stdin.write(JSON.stringify(data)+'\n');}catch{finish({ok:false,error:'额度连接不可用',windows:[]});}};
    readline.createInterface({input:proc.stdout}).on('line',line=>{
      if(line.length>2*1024*1024)return;
      let m;try{m=JSON.parse(line);}catch{return;}
      if(m.id===1){
        if(m.error)return finish({ok:false,error:'Codex 额度接口未就绪',windows:[]});
        send({method:'initialized',params:{}});
        send({id:2,method:'account/read',params:{refreshToken:false}});
      } else if(m.id===2){
        if(m.error)return finish({ok:false,error:'暂时无法读取登录状态',windows:[]});
        const type=m.result?.account?.type;
        // Account details and credentials are neither stored nor displayed.
        if(type!=='chatgpt' && type!=='chatgptAuthTokens')return finish({ok:false,error:'请在 Codex 中使用 ChatGPT 订阅登录',windows:[],clearPrevious:true});
        send({id:3,method:'account/rateLimits/read',params:{}});
      } else if(m.id===3){
        if(m.error)return finish({ok:false,error:'暂时无法读取额度',windows:[]});
        const data=normalizeLimits(m.result);
        if(!data.ok)data.error='当前账户未返回 5 小时或每周额度';
        data.clearPrevious=!data.ok;
        finish(data);
      }
    });
    send({id:1,method:'initialize',params:{clientInfo:{name:'gpt_niang_usage',title:'GPT 娘额度挂件',version:pluginVersion}}});
  });
}

export function atomicJson(file,data) {
  fs.mkdirSync(path.dirname(file),{recursive:true});
  const tmp=file+'.'+process.pid+'.tmp';
  try{fs.writeFileSync(tmp,JSON.stringify(data,null,2)+'\n');fs.renameSync(tmp,file);}
  finally{try{fs.unlinkSync(tmp);}catch{}}
}

export function freshness(window,observedAt,now=Date.now()) {
  if(!window || !Number.isFinite(observedAt))return 'unavailable';
  if(window.resetsAt*1000<=now)return 'expired';
  return now-observedAt>180000?'stale':'fresh';
}
