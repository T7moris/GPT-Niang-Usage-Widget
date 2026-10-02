import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {randomUUID} from 'node:crypto';
import {atomicJson} from './usage.mjs';
import {healthyWorker,readJson} from './worker-state.mjs';

const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));

// All callers request the same single writer; even headless MCP/control queries
// use watch.mjs instead of starting a separate account query.
export async function requestRefresh(config,configPath,{timeoutMs=45000,startWorker=()=>{
  const child=spawn(config.nodePath??process.execPath,[path.join(path.dirname(configPath),'runtime','watch.mjs'),configPath,'0'],{windowsHide:true,detached:true,stdio:'ignore'});
  child.on('error',()=>{});child.unref();
},pollMs=100,restartIntervalMs=5000}={}) {
  const id=randomUUID(),at=Date.now();
  const requestFile=path.join(config.dataDir,'refresh-requests',id+'.json');
  const resultFile=path.join(config.dataDir,'refresh-results',id+'.json');
  try {
    atomicJson(requestFile,{id,at,expiresAt:at+timeoutMs});
    let lastStart=at;
    if(!healthyWorker(config.dataDir))startWorker();
    while(Date.now()-at<timeoutMs) {
      const result=readJson(resultFile);
      if(result?.requestId===id && result.snapshot && typeof result.snapshot==='object')return result.snapshot;
      if(Date.now()-lastStart>=restartIntervalMs && !healthyWorker(config.dataDir)) {
        lastStart=Date.now();startWorker();
      }
      await pause(pollMs);
    }
    return {ok:false,queryOk:false,error:'额度刷新超时，请稍后重试',windows:[],clearPrevious:true};
  } finally {
    for(const file of [requestFile,resultFile])try{fs.unlinkSync(file);}catch{}
  }
}

export function readPendingRequests(dataDir,now=Date.now()) {
  const dir=path.join(dataDir,'refresh-requests');
  let names;try{names=fs.readdirSync(dir);}catch{return [];}
  const requests=[];
  for(const name of names) {
    if(!/^[0-9a-f-]{36}\.json$/i.test(name))continue;
    const file=path.join(dir,name),request=readJson(file);
    if(!request || request.id+'.json'!==name || !Number.isFinite(request.expiresAt) || request.expiresAt<=now || request.expiresAt>now+60000) {
      try{fs.unlinkSync(file);}catch{};continue;
    }
    requests.push({...request,file});
  }
  return requests;
}

export function completeRequests(dataDir,requests,snapshot) {
  for(const request of requests) {
    atomicJson(path.join(dataDir,'refresh-results',request.id+'.json'),{requestId:request.id,snapshot});
    try{fs.unlinkSync(request.file);}catch{}
  }
}

export function cleanRefreshResults(dataDir,now=Date.now()) {
  const dir=path.join(dataDir,'refresh-results');
  let names;try{names=fs.readdirSync(dir);}catch{return;}
  for(const name of names) {
    if(!/^[0-9a-f-]{36}\.json$/i.test(name))continue;
    const file=path.join(dir,name);
    try{if(now-fs.statSync(file).mtimeMs>60000)fs.unlinkSync(file);}catch{}
  }
}
