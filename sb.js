/* قدّها · Supabase connection shared by the game (/), phone pages (/r/, /h/, /w/).
   The URL and publishable key are public by design: the database only allows what supabase/schema.sql exposes.
   When they are empty, every online feature hides itself and the game works offline as before. */
(function(){
  var CFG=window.GADDHA_SB_CFG||{
    url:'https://nxhlmlgcveokoqdegqaa.supabase.co',
    key:'sb_publishable_BOPfNiIHdUXjHLcDvhhCpg_TpWjTNtx',   // publishable key (never the secret / service_role key)
    google:false   // turn on after Google is set up in Supabase → Authentication → Providers
  };
  var LIB='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.112.4/dist/umd/supabase.js';
  var client=null,loading=null;
  function load(){
    if(client)return Promise.resolve(client);
    if(!CFG.url||!CFG.key)return Promise.reject(new Error('not configured'));
    if(!loading)loading=new Promise(function(res,rej){
      if(window.supabase&&window.supabase.createClient)return res();
      var s=document.createElement('script');s.src=LIB;s.onload=function(){res()};s.onerror=function(){loading=null;rej(new Error('lib'))};document.head.appendChild(s);
    }).then(function(){client=window.supabase.createClient(CFG.url,CFG.key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,storageKey:'gaddha.auth',flowType:'pkce'}});return client});
    return loading;
  }
  function rpc(name,args){return load().then(function(c){return c.rpc(name,args||{})}).then(function(r){if(r.error)throw r.error;return r.data})}
  /* room(name): realtime broadcast channel. Register handlers with .on(event, fn) right after creating it. */
  function room(name){
    var handlers={},ch=null,up=false,queue=[],api={status:'connecting',onstatus:null};
    api.on=function(ev,fn){(handlers[ev]=handlers[ev]||[]).push(fn);if(ch)bind(ev);return api};
    function bind(ev){if(bound[ev])return;bound[ev]=1;ch.on('broadcast',{event:ev},function(m){(handlers[ev]||[]).forEach(function(f){try{f(m.payload)}catch(e){}})})}
    var bound={};
    api.send=function(ev,p){if(up)ch.send({type:'broadcast',event:ev,payload:p});else{queue.push([ev,p]);if(queue.length>50)queue.shift()}};
    api.close=function(){try{if(ch&&client)client.removeChannel(ch)}catch(e){}ch=null;up=false};
    function st(v){api.status=v;if(api.onstatus)try{api.onstatus(v)}catch(e){}}
    load().then(function(c){
      ch=c.channel(name,{config:{broadcast:{self:false,ack:false}}});
      Object.keys(handlers).forEach(bind);
      ch.subscribe(function(s){
        if(s==='SUBSCRIBED'){up=true;st('on');queue.splice(0).forEach(function(q){api.send(q[0],q[1])})}
        else if(s==='CHANNEL_ERROR'||s==='TIMED_OUT'||s==='CLOSED'){up=false;st('off')}
      });
    }).catch(function(){st('off')});
    return api;
  }
  var code=function(n){var a='abcdefghjkmnpqrstuvwxyz23456789',o='';var r=new Uint8Array(n||8);crypto.getRandomValues(r);for(var i=0;i<r.length;i++)o+=a[r[i]%a.length];return o};
  window.GADDHA_SB={configured:function(){return !!(CFG.url&&CFG.key)},google:function(){return !!CFG.google},client:load,rpc:rpc,room:room,code:code};
})();
