import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {resolveCodexExecutable} from '../runtime/usage.mjs';

function fixture(t){
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'gpt-niang-codex-path-'));
  const files=[],directories=[];
  t.after(()=>{
    for(const file of files){if(fs.existsSync(file))fs.unlinkSync(file);}
    for(const directory of directories.reverse()){if(fs.existsSync(directory))fs.rmdirSync(directory);}
    fs.rmdirSync(root);
  });
  function write(relative,age=0){
    const file=path.join(root,relative);const parent=path.dirname(file);
    const missing=[];let at=parent;
    while(at!==root && !fs.existsSync(at)){missing.push(at);at=path.dirname(at);}
    for(const directory of missing.reverse()){fs.mkdirSync(directory);directories.push(directory);}
    fs.writeFileSync(file,'fixture');files.push(file);
    const timestamp=new Date(Date.now()-age);fs.utimesSync(file,timestamp,timestamp);
    return file;
  }
  return {root,write};
}

test('a valid configured CLI is preserved',t=>{
  const {root,write}=fixture(t);const configured=write('custom/codex.exe');
  write('OpenAI/Codex/bin/new/codex.exe');
  assert.equal(resolveCodexExecutable(configured,{env:{LOCALAPPDATA:root},platform:'win32'}),configured);
});

test('a deleted update folder falls back to the newest installed desktop CLI',t=>{
  const {root,write}=fixture(t);
  write('OpenAI/Codex/bin/older/codex.exe',60000);
  const latest=write('OpenAI/Codex/bin/newer/codex.exe');
  write('OpenAI/Codex/bin/incomplete/other.exe');
  const deleted=path.join(root,'OpenAI/Codex/bin/deleted/codex.exe');
  assert.equal(resolveCodexExecutable(deleted,{env:{LOCALAPPDATA:root,PATH:path.join(root,'deleted')},platform:'win32'}),latest);
});

test('the next refresh discovers another app update without restarting the worker',t=>{
  const {root,write}=fixture(t);const old=write('OpenAI/Codex/bin/old/codex.exe',60000);
  const env={LOCALAPPDATA:root};const deleted=path.join(root,'removed/codex.exe');
  assert.equal(resolveCodexExecutable(deleted,{env,platform:'win32'}),old);
  fs.unlinkSync(old);const next=write('OpenAI/Codex/bin/next/codex.exe');
  assert.equal(resolveCodexExecutable(deleted,{env,platform:'win32'}),next);
});

test('PATH is a fallback and ignores blank, missing, and directory entries',t=>{
  const {root,write}=fixture(t);const cli=write('path-bin/codex.exe');
  const missing=path.join(root,'missing/codex.exe');
  assert.equal(resolveCodexExecutable(missing,{env:{Path:';'+path.join(root,'absent')+';"'+path.dirname(cli)+'"'},platform:'win32'}),cli);
  assert.equal(resolveCodexExecutable(missing,{env:{},platform:'win32'}),missing);
  assert.equal(resolveCodexExecutable(root,{env:{},platform:'win32'}),root);
});
