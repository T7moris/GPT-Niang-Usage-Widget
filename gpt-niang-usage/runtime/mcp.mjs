import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import {fileURLToPath} from 'node:url';
import {readUsage,atomicJson,freshness} from './usage.mjs';
import {pluginVersion} from './metadata.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const send=m=>process.stdout.write(JSON.stringify(m)+'\n');
const tool={name:'get_codex_usage',description:'读取当前 ChatGPT 账户的 Codex 5 小时和每周额度，返回已用、剩余百分比与北京时间重置时间。只读，不创建聊天或调用模型。',inputSchema:{type:'object',properties:{},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,idempotentHint:true,openWorldHint:true}};
async function handle(m){
  if(m.id===undefined)return;
  try{
    let result;
    switch(m.method){
      case 'initialize': result={protocolVersion:m.params?.protocolVersion??'2024-11-05',capabilities:{tools:{}},serverInfo:{name:'gpt-niang-usage',version:pluginVersion}};break;
      case 'ping':result={};break;
      case 'tools/list':result={tools:[tool]};break;
      case 'tools/call':{
        if(m.params?.name!==tool.name)throw new Error('Unknown tool');
        const config=JSON.parse(fs.readFileSync(path.join(root,'installation.json'),'utf8').replace(/^\uFEFF/,''));
        const r=await readUsage(config.codexPath);
        if(r.ok)atomicJson(path.join(config.dataDir,'status.json'),r);
        const data={ok:r.ok,source:'Codex 官方订阅额度接口',plan:r.plan,observedAt:r.observedAt?new Date(r.observedAt).toISOString():null,error:r.error,windows:r.windows.map(w=>({...w,state:freshness(w,r.observedAt),resetBeijing:new Intl.DateTimeFormat('zh-CN',{timeZone:'Asia/Shanghai',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hour12:false}).format(new Date(w.resetsAt*1000))}))};
        result={content:[{type:'text',text:JSON.stringify(data)}],isError:!r.ok};break;
      }
      default:send({jsonrpc:'2.0',id:m.id,error:{code:-32601,message:'Method not found'}});return;
    }
    send({jsonrpc:'2.0',id:m.id,result});
  }catch{send({jsonrpc:'2.0',id:m.id,error:{code:-32603,message:'GPT 娘额度服务暂不可用，请检查本地安装'}});}
}
readline.createInterface({input:process.stdin}).on('line',line=>{
  if(line.length>1024*1024)return;
  try{void handle(JSON.parse(line));}catch{send({jsonrpc:'2.0',id:null,error:{code:-32700,message:'Invalid JSON'}});}
});
