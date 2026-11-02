import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
RAW='raw'; OUT=sys.argv[1] if len(sys.argv)>1 else 'out/en'
os.makedirs(OUT, exist_ok=True)
W,H=1320,2868
DY=640
def font(path,size,var):
    f=ImageFont.truetype(path,size); f.set_variation_by_name(var); return f
SERIF='/System/Library/Fonts/NewYork.ttf'; SANS='/System/Library/Fonts/SFNS.ttf'
DARK=dict(top=(58,38,24), bot=(22,15,10), glow=(212,165,116), head=(250,238,218), sub=(214,186,148), gold=(255,214,0))
LIGHT=dict(top=(246,238,226), bot=(228,210,184), glow=(255,255,255), head=(43,29,20), sub=(110,84,60), gold=(196,150,40))
def background(t):
    bg=Image.new('RGB',(W,H))
    d=ImageDraw.Draw(bg)
    for y in range(H):
        k=y/(H-1); d.line([(0,y),(W,y)], fill=tuple(int(t['top'][i]*(1-k)+t['bot'][i]*k) for i in range(3)))
    glow=Image.new('L',(W,H),0); ImageDraw.Draw(glow).ellipse([W*0.05,H*0.22,W*0.95,H*0.78],fill=70)
    glow=glow.filter(ImageFilter.GaussianBlur(260))
    return Image.composite(Image.new('RGB',(W,H),t['glow']),bg,glow)
def rounded_mask(size,r):
    m=Image.new('L',size,0); ImageDraw.Draw(m).rounded_rectangle([0,0,size[0]-1,size[1]-1],r,fill=255); return m
def device(shot, scale=0.84):
    s=Image.open(os.path.join(RAW,shot+'.png')).convert('RGB')
    sw,sh=int(s.width*scale),int(s.height*scale); s=s.resize((sw,sh),Image.LANCZOS)
    r=int(186*scale); b=18
    frame=Image.new('RGBA',(sw+2*b,sh+2*b),(0,0,0,0))
    ImageDraw.Draw(frame).rounded_rectangle([0,0,sw+2*b-1,sh+2*b-1],r+b,fill=(12,12,12,255),outline=(70,66,62,255),width=3)
    frame.paste(s,(b,b),rounded_mask((sw,sh),r))
    return frame
def compose(name, shot, lines, sub, theme=DARK, dots=False):
    t=theme; img=background(t)
    dev=device(shot); dx=(W-dev.width)//2; dy=DY
    sh=Image.new('L',(W,H),0); ImageDraw.Draw(sh).rounded_rectangle([dx+10,dy+40,dx+dev.width-10,dy+dev.height+30],150,fill=150 if t is DARK else 90)
    sh=sh.filter(ImageFilter.GaussianBlur(45))
    img=Image.composite(Image.new('RGB',(W,H),(0,0,0)),img,sh)
    img.paste(dev,(dx,dy),dev)
    d=ImageDraw.Draw(img)
    hf=font(SERIF,118,'Bold'); sf=font(SANS,52,'Medium')
    y=150
    if dots:
        for i in range(5):
            cx=W//2+(i-2)*46; d.ellipse([cx-15,y-15,cx+15,y+15],fill=t['gold'])
        y+=50
    for ln in lines:
        w=d.textlength(ln,font=hf); d.text(((W-w)/2,y),ln,font=hf,fill=t['head']); y+=132
    y+=22
    w=d.textlength(sub,font=sf); d.text(((W-w)/2,y),sub,font=sf,fill=t['sub'])
    img.save(os.path.join(OUT,name+'.png'),optimize=True)
    print(name, img.size, img.mode)
SLIDES=[
 ('01_hero','A_light',['Pente,','right in iMessage'],'Challenge friends without leaving the chat.',DARK,True),
 ('02_capture','B_light',['Sandwich a pair.','Capture it.'],'Red rings preview exactly what you’ll take.',DARK,False),
 ('03_five','C_light',['Five in a row','wins the game'],'The winning line glows gold before you send.',DARK,False),
 ('04_message','E_transcript',['Every move','is a message'],'Play at your own pace. No accounts needed.',DARK,False),
 ('05_win','D_light',['Claim victory,','then rematch'],'One tap on Play Again starts the next game.',DARK,False),
 ('06_dark','A_dark',['Beautiful in','Dark Mode'],'A walnut board that’s easy on the eyes.',LIGHT,False),
 ('07_rules','rules_light',['Learn it in','seconds'],'A one-card primer the first time you play.',DARK,False),
]
if __name__=='__main__':
    for s in SLIDES: compose(*s)
