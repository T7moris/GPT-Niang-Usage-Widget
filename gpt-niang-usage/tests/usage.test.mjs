import test from 'node:test';
import assert from 'node:assert/strict';
import {EventEmitter} from 'node:events';
import {PassThrough} from 'node:stream';
import {normalizeLimits,freshness,readUsage} from '../runtime/usage.mjs';
import {mergeUsageSnapshot} from '../runtime/refresh-queue.mjs';
const w=(used=10,mins=300)=>({usedPercent:used,windowDurationMins:mins,resetsAt:2000000000});
test('prefer current codex bucket over legacy and unrelated model buckets',()=>{
  const r=normalizeLimits({rateLimits:{primary:w(90)},rateLimitsByLimitId:{codex:{primary:w(12),secondary:w(61,10080)},other:{primary:w(98)}}},1000);
  assert.deepEqual(r.windows.map(x=>[x.minutes,x.used,x.remaining]),[[300,12,88],[10080,61,39]]);
});
test('missing current bucket does not borrow a different account or meter',()=>{
  assert.equal(normalizeLimits({rateLimits:{primary:w()},rateLimitsByLimitId:{other:{primary:w()}}}).ok,false);
});
test('missing and invalid fields stay unavailable, valid zero and full usage survive',()=>{
  for(const x of [null,{}, {usedPercent:null,windowDurationMins:300,resetsAt:2000000000},w(-1),w(101),w(NaN),w(5,60),{...w(),resetsAt:null}])assert.equal(normalizeLimits({rateLimits:{primary:x}}).ok,false);
  assert.equal(normalizeLimits({rateLimits:{primary:w(0)}}).windows[0].remaining,100);
  assert.equal(normalizeLimits({rateLimits:{primary:w(100)}}).windows[0].remaining,0);
});
test('passed reset stays expired instead of invented replenishment',()=>{
  assert.equal(freshness({resetsAt:2},1000,3000),'expired');
  assert.equal(freshness({resetsAt:1000},1000,200000),'stale');
  assert.equal(freshness({resetsAt:1000},1000,2000),'fresh');
});
test('missing Codex executable returns a bounded actionable failure',async()=>{
  const r=await readUsage('Z:/not-a-codex-executable.exe',{timeoutMs:2000});
  assert.equal(r.ok,false);assert.deepEqual(r.windows,[]);
});
test('account read protocol error retains a valid quota snapshot',async()=>{
  const calls=[];
  const spawnProcess=()=>{
    const proc=new EventEmitter();
    proc.stdin=new PassThrough();proc.stdout=new PassThrough();proc.stderr=new PassThrough();
    proc.kill=()=>{};
    let pending='';
    proc.stdin.on('data',chunk=>{
      pending+=chunk.toString();
      let at;
      while((at=pending.indexOf('\n'))>=0){
        const request=JSON.parse(pending.slice(0,at));pending=pending.slice(at+1);
        calls.push(request.method);
        if(request.method==='initialize')queueMicrotask(()=>proc.stdout.write(JSON.stringify({id:request.id,result:{}})+'\n'));
        else if(request.method==='account/read')queueMicrotask(()=>proc.stdout.write(JSON.stringify({id:request.id,error:{code:-32603,message:'temporary account service error'}})+'\n'));
      }
    });
    return proc;
  };
  const response=await readUsage('fake-codex',{timeoutMs:2000,spawnProcess});
  assert.equal(response.ok,false);assert.equal(response.clearPrevious,undefined);
  assert.deepEqual(calls,['initialize','initialized','account/read']);
  const previous=normalizeLimits({rateLimits:{primary:w(12)}},1000);
  const snapshot=mergeUsageSnapshot(previous,response,2000);
  assert.equal(snapshot.ok,true);assert.equal(snapshot.observedAt,1000);
  assert.equal(snapshot.windows[0].remaining,88);assert.equal(snapshot.checkedAt,2000);
  assert.equal(snapshot.error,'暂时无法读取登录状态');
});
