import os, sys
import compose as C
from PIL import Image, ImageDraw, ImageFilter
C.W,C.H=2064,2752
OUT=sys.argv[1] if len(sys.argv)>1 else 'out/ipad_en'; os.makedirs(OUT,exist_ok=True)
def ipad(shot, scale):
    s=Image.open(os.path.join(C.RAW,shot+'.png')).convert('RGB')
    sw,sh=int(s.width*scale),int(s.height*scale); s=s.resize((sw,sh),Image.LANCZOS)
    r=int(55*scale*2); b=28
    f=Image.new('RGBA',(sw+2*b,sh+2*b),(0,0,0,0))
    ImageDraw.Draw(f).rounded_rectangle([0,0,sw+2*b-1,sh+2*b-1],r+b,fill=(12,12,12,255),outline=(70,66,62,255),width=4)
    f.paste(s,(b,b),C.rounded_mask((sw,sh),r)); return f
def compose(name, shot, line, sub, t=C.DARK):
    W,H=C.W,C.H; img=C.background(t)
    dev=ipad(shot,0.80); dx=(W-dev.width)//2; dy=H-dev.height+40
    sh=Image.new('L',(W,H),0); ImageDraw.Draw(sh).rounded_rectangle([dx+20,dy+50,dx+dev.width-20,dy+dev.height],120,fill=150)
    img=Image.composite(Image.new('RGB',(W,H),(0,0,0)),img,sh.filter(ImageFilter.GaussianBlur(60)))
    img.paste(dev,(dx,dy),dev)
    d=ImageDraw.Draw(img); hf=C.font(C.SERIF,128,'Bold'); sf=C.font(C.SANS,58,'Medium')
    y=120; w=d.textlength(line,font=hf); d.text(((W-w)/2,y),line,font=hf,fill=t['head'])
    y+=170; w=d.textlength(sub,font=sf); d.text(((W-w)/2,y),sub,font=sf,fill=t['sub'])
    img.save(os.path.join(OUT,name+'.png'),optimize=True); print(name,img.size)
SLIDES=[
 ('01_hero','ipad_A_card','Pente, right in iMessage','Challenge friends without leaving the chat.'),
 ('02_capture','ipad_B_card','Sandwich a pair. Capture it.','Red rings preview exactly what you’ll take.'),
 ('03_five','ipad_C_card','Five in a row wins','The winning line glows gold before you send.'),
 ('04_win','ipad_D','Claim victory, then rematch','Every move is a message — no accounts needed.'),
]
if __name__=='__main__':
    for s in SLIDES: compose(*s)
