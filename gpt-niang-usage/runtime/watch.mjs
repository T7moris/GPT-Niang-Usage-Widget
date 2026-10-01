import fs from 'node:fs';
import path from 'node:path';
import {readUsage,atomicJson} from './usage.mjs';
import {createRefreshQueue,mergeUsageSnapshot,readRefreshRequest} from './refresh-queue.mjs';
const config=JSON.parse(fs.readFileSync(process.argv[2],'utf8').replace(/^\uFEFF/,''));
const statusFile=path.join(config.dataDir,'status.json');
let status=null,requestToken=null;
try{status=JSON.parse(fs.readFileSync(statusFile,'utf8'));}catch{}
const refresh=createRefreshQueue(async()=>{
  const next=await readUsage(config.codexPath);
  status=mergeUsageSnapshot(status,next);
  atomicJson(statusFile,status);
},{onError:error=>{
  // A temporary filesystem failure must not stop the quota worker.
  const code=typeof error?.code==='string'?error.code:'IO';
  console.error('Quota snapshot could not be saved; next refresh will retry ('+code+').');
}});
const heartbeat=setInterval(()=>{
  if(fs.existsSync(path.join(config.dataDir,'stop.flag'))){clearInterval(heartbeat);process.exit(0);}
  // No background queries while Codex is not visible; a fresh query on return.
  let active=false;try{const p=JSON.parse(fs.readFileSync(path.join(config.dataDir,'presence.json'),'utf8').replace(/^\uFEFF/,''));active=p.visible && Date.now()-p.at<5000;}catch{}
  const request=readRefreshRequest(path.join(config.dataDir,'refresh.flag'));
  if(request!==null && request!==requestToken){requestToken=request;void refresh.request();}
  else if(active && !refresh.busy && Date.now()-refresh.lastRefresh>=60000)void refresh.request();
},1000);
process.on('SIGTERM',()=>process.exit(0));
process.on('SIGINT',()=>process.exit(0));
