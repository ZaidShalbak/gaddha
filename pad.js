/* قدّها · drawing pad shared by the game (/) and the phone reveal page (/r/).
   Strokes are stored in normalized 0..1 coordinates so the drawing survives resizes and re-renders.
   Live mirroring: the drawing side passes opt.onlive(msg); the watching side calls pad.apply(msg).
   Messages: {op:'s', s:stroke, a:aspect} (stroke added/updated), {op:'undo'}, {op:'clear'}, {op:'all', list:[...], a}. */
(function(){
  var COLORS=['#161616','#f0475a','#2f9e5f','#1d6fd6','#e0a92a','#8a4fd6','#8b5a2b'];
  var SIZES=[{w:.008,l:'رفيع'},{w:.018,l:'عريض'}];
  var CSS='.gpad{display:flex;flex-direction:column;gap:8px;width:100%;min-height:0}'
   +'.gpad-box{position:relative;flex:1;min-height:0;border-radius:20px;overflow:hidden;background:#fff;box-shadow:inset 0 0 0 2px #e4e1d8}'
   +'.gpad-box canvas{position:absolute;inset:0;width:100%;height:100%;touch-action:none;cursor:crosshair;display:block}'
   +'.gpad-bar{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:6px}'
   +'.gpad-c{width:34px;height:34px;border-radius:50%;border:3px solid #fff;box-shadow:0 0 0 1.5px #e4e1d8;cursor:pointer;padding:0}'
   +'.gpad-c[aria-pressed="true"]{box-shadow:0 0 0 3px #161616}'
   +'.gpad-t,.gpad-x{font:inherit;font-weight:800;min-width:40px;height:40px;border-radius:12px;border:0;background:#fff;color:#161616;box-shadow:0 1px 4px rgba(22,22,22,.1);display:inline-grid;place-items:center;cursor:pointer;padding:0 10px}'
   +'.gpad-t i{display:block;border-radius:50%;background:currentColor}'
   +'.gpad-t[aria-pressed="true"]{background:#161616;color:#fff}'
   +'.gpad-x{color:#c92a3a}';
  if(!document.getElementById('gpad-css')){var st=document.createElement('style');st.id='gpad-css';st.textContent=CSS;document.head.appendChild(st)}
  function el(tag,cls,html){var e=document.createElement(tag);if(cls)e.className=cls;if(html!=null)e.innerHTML=html;return e}
  function create(host,opt){
    opt=opt||{};
    var strokes=opt.strokes||[],ro=!!opt.readonly,color=COLORS[0],size=0,erase=false,cur=null,aspect=opt.aspect||0,lastSend=0,sendT=null;
    var live=function(m){if(opt.onlive){m.a=W&&H?W/H:0;opt.onlive(m)}};
    var liveMove=function(){var now=Date.now();clearTimeout(sendT);if(now-lastSend>60){lastSend=now;if(cur)live({op:'s',s:cur})}else sendT=setTimeout(liveMove,60-(now-lastSend))};
    var uid=function(){return Math.random().toString(36).slice(2,9)};
    host.innerHTML='';host.classList.add('gpad');
    var box=el('div','gpad-box'),cv=el('canvas');box.appendChild(cv);
    var bar=el('div','gpad-bar');
    if(!ro){
      COLORS.forEach(function(c,i){var b=el('button','gpad-c');b.type='button';b.style.background=c;b.setAttribute('aria-label','لون');b.setAttribute('aria-pressed',String(i===0));
        b.onclick=function(){color=c;erase=false;sync()};b.dataset.c=c;bar.appendChild(b)});
      SIZES.forEach(function(s,i){var b=el('button','gpad-t','<i style="width:'+(i?14:7)+'px;height:'+(i?14:7)+'px"></i>');b.type='button';b.setAttribute('aria-label',s.l);b.dataset.s=i;b.onclick=function(){size=i;sync()};bar.appendChild(b)});
      var er=el('button','gpad-t','<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 16l9-9 6 6-7 7H7z"/><path d="M12 20h8"/></svg>');er.type='button';er.setAttribute('aria-label','ممحاة');er.onclick=function(){erase=!erase;sync()};bar.appendChild(er);
      var un=el('button','gpad-t','<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 14L4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/></svg>');un.type='button';un.setAttribute('aria-label','تراجع');un.onclick=function(){strokes.pop();draw();live({op:'undo'});if(opt.onchange)opt.onchange(strokes)};bar.appendChild(un);
      var cl=el('button','gpad-x','امسح');cl.type='button';cl.onclick=function(){strokes.length=0;draw();live({op:'clear'});if(opt.onchange)opt.onchange(strokes)};bar.appendChild(cl);
    }
    host.appendChild(box);if(!ro)host.appendChild(bar);
    function sync(){
      bar.querySelectorAll('.gpad-c').forEach(function(b){b.setAttribute('aria-pressed',String(!erase&&b.dataset.c===color))});
      bar.querySelectorAll('[data-s]').forEach(function(b){b.setAttribute('aria-pressed',String(+b.dataset.s===size))});
      if(er)er.setAttribute('aria-pressed',String(erase));
    }
    sync();
    var ctx=cv.getContext('2d'),W=0,H=0;
    function fit(){
      if(aspect){var hr=host.getBoundingClientRect(),bh=bar.parentNode?bar.getBoundingClientRect().height+8:0,aw=hr.width,ah=Math.max(40,hr.height-bh),w=aw,h=w/aspect;if(h>ah){h=ah;w=h*aspect}box.style.flex='none';box.style.width=w+'px';box.style.height=h+'px';box.style.alignSelf='center'}
      var r=box.getBoundingClientRect(),d=window.devicePixelRatio||1;W=r.width;H=r.height;cv.width=Math.round(W*d);cv.height=Math.round(H*d);ctx.setTransform(d,0,0,d,0,0);draw()}
    function line(s){
      if(!s.p.length)return;var k=Math.min(W,H)||1;
      ctx.strokeStyle=s.e?'#fff':s.c;ctx.fillStyle=ctx.strokeStyle;ctx.lineWidth=s.w*k;ctx.lineCap='round';ctx.lineJoin='round';
      if(s.p.length===1){ctx.beginPath();ctx.arc(s.p[0][0]*W,s.p[0][1]*H,s.w*k/2,0,7);ctx.fill();return}
      ctx.beginPath();ctx.moveTo(s.p[0][0]*W,s.p[0][1]*H);
      for(var i=1;i<s.p.length-1;i++){var a=s.p[i],b=s.p[i+1];ctx.quadraticCurveTo(a[0]*W,a[1]*H,(a[0]+b[0])/2*W,(a[1]+b[1])/2*H)}
      var l=s.p[s.p.length-1];ctx.lineTo(l[0]*W,l[1]*H);ctx.stroke();
    }
    function draw(){ctx.fillStyle='#fff';ctx.fillRect(0,0,W,H);strokes.forEach(line)}
    function pt(e){var r=cv.getBoundingClientRect();return[Math.max(0,Math.min(1,(e.clientX-r.left)/r.width)),Math.max(0,Math.min(1,(e.clientY-r.top)/r.height))]}
    if(!ro){
      cv.addEventListener('pointerdown',function(e){e.preventDefault();cv.setPointerCapture(e.pointerId);cur={id:uid(),c:color,w:erase?.05:SIZES[size].w,e:erase,p:[pt(e)]};strokes.push(cur);line(cur);live({op:'s',s:cur})});
      cv.addEventListener('pointermove',function(e){if(!cur)return;e.preventDefault();var p=pt(e),q=cur.p[cur.p.length-1];if(Math.abs(p[0]-q[0])+Math.abs(p[1]-q[1])<.002)return;cur.p.push(p);draw();liveMove()});
      var end=function(){if(cur){clearTimeout(sendT);live({op:'s',s:cur});cur=null;if(opt.onchange)opt.onchange(strokes)}};
      cv.addEventListener('pointerup',end);cv.addEventListener('pointercancel',end);
    }
    var ro2=window.ResizeObserver?new ResizeObserver(fit):null;if(ro2)ro2.observe(host);else window.addEventListener('resize',fit);
    fit();
    function apply(m){
      if(!m)return;
      if(m.a&&Math.abs((m.a||0)-aspect)>.01){aspect=m.a;fit()}
      if(m.op==='s'&&m.s){var i=-1;for(var k=0;k<strokes.length;k++)if(strokes[k].id===m.s.id){i=k;break}if(i<0)strokes.push(m.s);else strokes[i]=m.s;draw()}
      else if(m.op==='undo'){strokes.pop();draw()}
      else if(m.op==='clear'){strokes.length=0;draw()}
      else if(m.op==='all'){strokes.length=0;(m.list||[]).forEach(function(x){strokes.push(x)});draw()}
    }
    return{strokes:strokes,apply:apply,snapshot:function(){return{op:'all',list:strokes.slice(),a:W&&H?W/H:0}},destroy:function(){if(ro2)ro2.disconnect()}};
  }
  window.GADDHA_PAD={create:create};
})();
