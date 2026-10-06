import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
import readline from 'node:readline';
import {createHash,randomUUID} from 'node:crypto';
import {pluginVersion} from './metadata.mjs';

export function normalizeLimits(result, now=Date.now()) {
  const hasBuckets=result && Object.hasOwn(result,'rateLimitsByLimitId') && result.rateLimitsByLimitId!==null;
  const limit = hasBuckets ? result.rateLimitsByLimitId?.codex : result?.rateLimits;
  if(!limit || typeof limit!=='object' || Array.isArray(limit))return {ok:false,queryOk:false,source:'official',observedAt:now,plan:null,windows:[],error:'Codex 额度接口未返回有效额度数据'};
  const windows = [];
  let invalid=false;
  for (const key of ['primary','secondary']) {
    const raw = limit?.[key];
    const mins = raw?.windowDurationMins;
    const used = raw?.usedPercent;
    const reset = raw?.resetsAt;
    if(raw===null || raw===undefined)continue;
    if(typeof raw!=='object' || !Number.isFinite(mins) || mins<=0 || typeof used!=='number' || !Number.isFinite(used) || used<0 || used>100){invalid=true;continue;}
    if(![300,10080].includes(mins))continue;
    if(windows.some(window=>window.minutes===mins)){invalid=true;continue;}
    // DateTimeOffset must also be able to represent the Beijing (+08:00) view.
    windows.push({label:mins===300?'5 小时':'每周',minutes:mins,used,remaining:100-used,resetsAt:typeof reset==='number' && Number.isFinite(reset) && reset>0 && reset<=253402271999?reset:null});
  }
  windows.sort((a,b)=>a.minutes-b.minutes);
  return {ok:windows.length>0,queryOk:!invalid,source:'official',observedAt:now,plan:typeof limit?.planType==='string'?limit.planType:null,windows,...(invalid?{error:'Codex 额度接口返回的窗口数据不完整'}:{})};
}

// Only a fingerprint of public account/read identity fields is persisted.
// Missing identity cannot safely authorize reuse of another query's snapshot.
export function accountFingerprint(account) {
  const fields=['id','accountId','chatgptAccountId','email'];
  const identity=fields.map(key=>[key,typeof account?.[key]==='string'?account[key].trim():null]).filter(([,value])=>value);
  if(identity.length===0)return null;
  return createHash('sha256').update(JSON.stringify([account.type,account.planType??null,identity])).digest('hex');
}

// The desktop app replaces its hash-named CLI folder during updates. Resolve
// the executable on every refresh rather than pinning the install-time path.
export function resolveCodexExecutable(configuredPath,{env=process.env,platform=process.platform}={}) {
  const isFile=file=>{try{return fs.statSync(file).isFile();}catch{return false;}};
  if(typeof configuredPath==='string' && isFile(configuredPath))return configuredPath;
  const executable=platform==='win32'?'codex.exe':'codex';
  if(platform==='darwin'){
    // Finder launches with a minimal PATH. Prefer the CLI shipped with the app.
    // An explicit app root also lets tests isolate themselves from real logins.
    const applications=env.GPT_NIANG_CODEX_APP?[env.GPT_NIANG_CODEX_APP]:[
      '/Applications/Codex.app',
      ...(env.HOME?[path.join(env.HOME,'Applications','Codex.app')]:[])
    ];
    for(const app of applications){
      for(const relative of ['Contents/Resources/codex-cli/bin/codex','Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex','Contents/Resources/codex']){
        const file=path.join(app,relative);
        if(isFile(file))return file;
      }
    }
  }

  const localData=env.LOCALAPPDATA??env.LocalAppData;
  if(platform==='win32' && localData){
    const root=path.join(localData,'OpenAI','Codex','bin');
    const candidates=[];
    const add=file=>{try{const stat=fs.statSync(file);if(stat.isFile())candidates.push({file,modified:stat.mtimeMs});}catch{}};
    add(path.join(root,executable));
    try{for(const entry of fs.readdirSync(root,{withFileTypes:true})){if(entry.isDirectory())add(path.join(root,entry.name,executable));}}catch{}
    candidates.sort((a,b)=>b.modified-a.modified||a.file.localeCompare(b.file));
    if(candidates.length)return candidates[0].file;
  }
  for(const directory of (env.PATH??env.Path??'').split(platform==='win32'?';':':')){
    const trimmed=directory.trim().replace(/^"(.*)"$/,'$1');
    if(!trimmed)continue;
    const file=path.join(trimmed,executable);
    if(isFile(file))return file;
  }
  return configuredPath;
}

// Only three read-only protocol methods are sent. There is no thread or model call.
export function readUsage(cli, {timeoutMs=18000,spawnProcess=spawn,onAccount=()=>{}}={}) {
  return new Promise(resolve=>{
    let finished=false,proc,lines,accountKey=null,expectedId=1;
    const failure=(error,errorCode)=>({ok:false,queryOk:false,error,windows:[],accountKey,clearPrevious:!accountKey,...(errorCode?{errorCode}:{})});
    const stopChild=()=>{try{proc?.stdin.end();proc?.kill();}catch{}};
    const finish=data=>{
      if(finished)return; finished=true; clearTimeout(timer);
      lines?.close();
      process.removeListener('exit',stopChild);
      stopChild();
      resolve(data);
    };
    const timer=setTimeout(()=>finish(failure('查询超时，稍后重试')),timeoutMs);
    try{proc=spawnProcess(cli,['app-server','--stdio'],{windowsHide:true,stdio:['pipe','pipe','pipe']});}
    catch{finish(failure('Codex 额度服务暂不可用'));return;}
    process.once('exit',stopChild);
    proc.stderr.on('data',()=>{}).on('error',()=>{});
    proc.on('error',error=>finish(failure(error.code==='ENOENT'?'未找到 Codex 程序，请检查客户端安装':'无法启动 Codex 额度服务',error.code)));
    proc.on('close',()=>finish(failure('Codex 额度服务已结束')));
    proc.stdout.on('error',()=>finish(failure('Codex 额度连接已结束')));
    proc.stdin.on('error',()=>finish(failure('Codex 额度连接已结束')));
    const send=data=>{try{proc.stdin.write(JSON.stringify(data)+'\n');}catch{finish(failure('额度连接不可用'));}};
    lines=readline.createInterface({input:proc.stdout});
    lines.on('line',line=>{
      if(finished)return;
      if(line.length>2*1024*1024)return;
      let m;try{m=JSON.parse(line);}catch{return;}
      if(!m || typeof m!=='object' || Array.isArray(m))return;
      if(m.id!==expectedId)return;
      if(m.id===1){
        if(m.error)return finish(failure('Codex 额度接口未就绪'));
        expectedId=null;
        send({method:'initialized',params:{}});
        expectedId=2;
        send({id:2,method:'account/read',params:{refreshToken:false}});
      } else if(m.id===2){
        if(m.error)return finish(failure('暂时无法读取登录状态'));
        const type=m.result?.account?.type;
        // Account details and credentials are neither stored nor displayed.
        if(type!=='chatgpt' && type!=='chatgptAuthTokens')return finish(failure('请在 Codex 中使用 ChatGPT 订阅登录'));
        accountKey=accountFingerprint(m.result.account);
        try{onAccount(accountKey);}catch{return finish(failure('无法保存账户切换状态'));}
        expectedId=3;
        send({id:3,method:'account/rateLimits/read',params:{}});
      } else if(m.id===3){
        if(m.error)return finish(failure('暂时无法读取额度'));
        const data=normalizeLimits(m.result);
        if(!data.ok && !data.error)data.error='当前账户未返回 5 小时或每周额度';
        data.clearPrevious=(data.queryOk && !data.ok) || !accountKey;
        data.accountKey=accountKey;
        finish(data);
      }
    });
    send({id:1,method:'initialize',params:{clientInfo:{name:'gpt_niang_usage',title:'GPT 娘额度挂件',version:pluginVersion}}});
  });
}

export function atomicJson(file,data) {
  fs.mkdirSync(path.dirname(file),{recursive:true});
  const tmp=file+'.'+process.pid+'.'+randomUUID()+'.tmp';
  try{fs.writeFileSync(tmp,JSON.stringify(data,null,2)+'\n');fs.renameSync(tmp,file);}
  finally{try{fs.unlinkSync(tmp);}catch{}}
}

export function freshness(window,observedAt,now=Date.now()) {
  if(!window || !Number.isFinite(observedAt))return 'unavailable';
  if(Number.isFinite(window.resetsAt) && window.resetsAt>0 && window.resetsAt*1000<=now)return 'expired';
  return now-observedAt>180000?'stale':'fresh';
}
