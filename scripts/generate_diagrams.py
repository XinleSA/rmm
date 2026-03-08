#!/usr/bin/env python3
"""Xinle 欣乐 — Network Architecture Diagram Generator v6.0"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
import os

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs', 'diagrams')
os.makedirs(OUT_DIR, exist_ok=True)

BG='#0a0a0f'; CARD='#141420'; BORDER='#2a2a3a'
PINK='#e94898'; ORANGE='#ff6b35'; BLUE='#60a5fa'; GREEN='#34d399'
YELLOW='#fbbf24'; PURPLE='#c084fc'; RED='#f87171'; GRAY='#8888aa'; WHITE='#f0f0f5'

def sfig(w=16,h=10):
    fig,ax=plt.subplots(figsize=(w,h))
    fig.patch.set_facecolor(BG); ax.set_facecolor(BG); ax.axis('off')
    return fig,ax

def bx(ax,x,y,w,h,c=CARD,b=BORDER,lw=1.5):
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle="round,pad=0.08",facecolor=c,edgecolor=b,linewidth=lw))

def tx(ax,x,y,t,s=9,c=WHITE,bold=False,ha='center',va='center'):
    ax.text(x,y,t,ha=ha,va=va,fontsize=s,color=c,fontweight='bold' if bold else 'normal')

def ar(ax,x1,y1,x2,y2,c=GRAY,lw=1.5,bi=False):
    ax.annotate('',xy=(x2,y2),xytext=(x1,y1),arrowprops=dict(arrowstyle='->',color=c,lw=lw))
    if bi: ax.annotate('',xy=(x1,y1),xytext=(x2,y2),arrowprops=dict(arrowstyle='->',color=c,lw=lw))

def save(fig,name):
    p=os.path.join(OUT_DIR,name)
    plt.tight_layout(pad=0.5)
    plt.savefig(p,dpi=150,bbox_inches='tight',facecolor=BG)
    plt.close()
    print(f'  [OK] {name}')

# ── Diagram 1: Network Overview ──────────────────────────────────────────────
def d1():
    fig,ax=sfig(18,11); ax.set_xlim(0,18); ax.set_ylim(0,11)
    tx(ax,9,10.5,'Xinle 欣乐 — Full Network Overview',14,PINK,True)
    # Cloudflare
    bx(ax,5,9.2,8,1.0,c='#0d1117',b=BLUE,lw=2)
    tx(ax,9,9.75,'☁  Cloudflare CDN / DNS  —  rmmx.xinle.biz',11,BLUE,True)
    tx(ax,9,9.4,'DNS-only (grey cloud) during initial setup; orange cloud optional after SSL',8,GRAY)
    ar(ax,9,9.2,9,8.3,BLUE,2)
    tx(ax,9.4,8.75,'HTTPS :443',8,BLUE,ha='left')
    # VPS box
    bx(ax,0.5,1.5,10,6.5,c='#0f0f1a',b=PINK,lw=2)
    tx(ax,5.5,7.7,'VPS — 184.105.7.78  |  Ubuntu 24.04.4 LTS  |  /docker_apps',9,PINK,True)
    # containers
    ctrs=[
        (0.8,6.2,'npm','jc21/nginx-proxy-manager',':80 :443 :81',BLUE),
        (3.3,6.2,'n8n','n8nio/n8n',':5678',GREEN),
        (5.8,6.2,'forgejo','forgejo:7',':3000',YELLOW),
        (8.3,6.2,'netlockrmm','netlock/rmm',':80',PURPLE),
        (0.8,4.5,'postgres','postgres:16',':5432',RED),
        (3.3,4.5,'pgadmin','dpage/pgadmin4',':80',RED),
        (5.8,4.5,'mysql','mysql:8.0',':3306',ORANGE),
        (8.3,4.5,'phpmyadmin','phpmyadmin',':80',ORANGE),
        (3.3,2.8,'landing','nginx:alpine',':80',PINK),
    ]
    for x,y,nm,img,port,col in ctrs:
        bx(ax,x,y,2.2,1.5,b=col)
        tx(ax,x+1.1,y+1.2,nm,8,col,True)
        tx(ax,x+1.1,y+0.85,img,6.5,GRAY)
        tx(ax,x+1.1,y+0.5,port,8,WHITE)
        tx(ax,x+1.1,y+0.2,'172.20.x.x',7,GRAY)
    tx(ax,5.5,2.1,'Docker Network: xinle_network  (172.20.0.0/16)',8,GRAY)
    # IPsec arrow
    ar(ax,10.5,5.5,13.5,5.5,GREEN,3,True)
    tx(ax,12.0,5.85,'IPsec IKEv2',10,GREEN,True)
    tx(ax,12.0,5.5,'AES-256 / SHA-256',8,GRAY)
    tx(ax,12.0,5.2,'UDP 500 / 4500',8,GRAY)
    # AI Site
    bx(ax,13.5,2.5,4.0,5.5,c='#0f0f1a',b=GREEN,lw=2)
    tx(ax,15.5,7.7,'AI Site',11,GREEN,True)
    tx(ax,15.5,7.35,'ai.xinle.biz',8,GRAY)
    bx(ax,13.7,5.8,3.6,1.0,b=PURPLE)
    tx(ax,15.5,6.35,'UDM Pro',9,PURPLE,True)
    tx(ax,15.5,6.0,'IPsec endpoint',7.5,GRAY)
    bx(ax,13.7,4.5,3.6,1.0,b=BLUE)
    tx(ax,15.5,5.05,'AI Server',9,BLUE,True)
    tx(ax,15.5,4.7,'10.1.0.x',7.5,GRAY)
    bx(ax,13.7,3.2,3.6,1.0,b=GRAY)
    tx(ax,15.5,3.75,'LAN: 10.1.0.0/24',9,GRAY)
    save(fig,'01_network_overview.png')

# ── Diagram 2: IPsec Flow ────────────────────────────────────────────────────
def d2():
    fig,ax=sfig(14,8); ax.set_xlim(0,14); ax.set_ylim(0,8)
    tx(ax,7,7.5,'IPsec IKEv2 — Connection Handshake Flow',13,PINK,True)
    bx(ax,0.5,1.0,3.5,5.8,c='#0f0f1a',b=PINK,lw=2)
    tx(ax,2.25,6.5,'VPS (strongSwan)',10,PINK,True)
    tx(ax,2.25,6.1,'184.105.7.78',8,GRAY)
    bx(ax,10.0,1.0,3.5,5.8,c='#0f0f1a',b=GREEN,lw=2)
    tx(ax,11.75,6.5,'UDM Pro (IKEv2)',10,GREEN,True)
    tx(ax,11.75,6.1,'ai.xinle.biz',8,GRAY)
    steps=[
        (5.2,'Phase 1: IKE_SA_INIT →',BLUE,False),
        (4.6,'← IKE_SA_INIT Response',BLUE,False),
        (3.8,'Phase 2: IKE_AUTH (PSK) →',GREEN,False),
        (3.2,'← IKE_AUTH Response',GREEN,False),
        (2.4,'⟺  Encrypted ESP Data Traffic',PINK,True),
    ]
    for y,lbl,col,bi in steps:
        ar(ax,4.0,y,10.0,y,col,1.8,bi)
        tx(ax,7.0,y+0.2,lbl,8,col)
    bx(ax,5.5,1.2,3.0,1.2,c='#0d1117',b=PINK)
    tx(ax,7.0,2.1,'Encryption Suite',8,PINK,True)
    tx(ax,7.0,1.75,'AES-256-CBC + SHA-256 HMAC',7.5,GRAY)
    tx(ax,7.0,1.45,'DH Group 14 (2048-bit MODP)',7.5,GRAY)
    save(fig,'02_ipsec_tunnel_flow.png')

# ── Diagram 3: IP Addressing ─────────────────────────────────────────────────
def d3():
    fig,ax=sfig(16,9); ax.set_xlim(0,16); ax.set_ylim(0,9)
    tx(ax,8,8.5,'IP Addressing Reference — Across the IPsec Tunnel',13,PINK,True)
    bx(ax,0.3,0.8,6.5,7.0,c='#0f0f1a',b=PINK,lw=2)
    tx(ax,3.55,7.5,'VPS Side',11,PINK,True)
    vps_rows=[
        ('Public IP','184.105.7.78',WHITE,'External / Cloudflare'),
        ('Tunnel IF xfrm0','172.20.10.1',GREEN,'Ping to verify tunnel'),
        ('Docker Gateway','172.20.0.1',BLUE,'xinle_network bridge'),
        ('n8n','172.20.x.x:5678',GREEN,'docker inspect n8n'),
        ('PostgreSQL','172.20.x.x:5432',RED,'docker inspect postgres'),
        ('Forgejo','172.20.x.x:3000',YELLOW,'docker inspect forgejo'),
        ('MySQL','172.20.x.x:3306',ORANGE,'docker inspect mysql'),
    ]
    for i,(nm,ip,col,note) in enumerate(vps_rows):
        y=6.7-i*0.82
        bx(ax,0.5,y-0.28,6.1,0.62,b=BORDER)
        tx(ax,1.6,y+0.03,nm,8,GRAY,ha='left')
        tx(ax,4.2,y+0.03,ip,8.5,col,True,ha='left')
    bx(ax,9.2,0.8,6.5,7.0,c='#0f0f1a',b=GREEN,lw=2)
    tx(ax,12.45,7.5,'AI Site Side',11,GREEN,True)
    ai_rows=[
        ('UDM Pro LAN','10.1.0.1',PURPLE,'Default gateway'),
        ('AI Server','10.1.0.x',BLUE,'Assign static in UniFi'),
        ('Full LAN','10.1.0.0/24',YELLOW,'All devices reachable'),
        ('Reach VPS host','172.20.10.1',GREEN,'Tunnel endpoint — ping'),
        ('Reach containers','172.20.x.x',BLUE,'Full Docker subnet'),
        ('Reach n8n','172.20.x.x:5678',GREEN,'Direct container access'),
    ]
    for i,(nm,ip,col,note) in enumerate(ai_rows):
        y=6.7-i*0.82
        bx(ax,9.4,y-0.28,6.1,0.62,b=BORDER)
        tx(ax,10.5,y+0.03,nm,8,GRAY,ha='left')
        tx(ax,13.1,y+0.03,ip,8.5,col,True,ha='left')
    ar(ax,6.8,4.5,9.2,4.5,GREEN,3,True)
    tx(ax,8.0,4.85,'IPsec Tunnel',10,GREEN,True)
    tx(ax,8.0,4.55,'AES-256 IKEv2',8,GRAY)
    save(fig,'03_ip_addressing.png')

# ── Diagram 4: Docker Network ────────────────────────────────────────────────
def d4():
    fig,ax=sfig(16,10); ax.set_xlim(0,16); ax.set_ylim(0,10)
    tx(ax,8,9.5,'Docker Network — xinle_network (172.20.0.0/16)',13,PINK,True)
    bx(ax,0.5,0.5,15,8.5,c='#0d0d18',b=PINK,lw=2)
    tx(ax,8,8.7,'xinle_network bridge  •  Gateway: 172.20.0.1  •  /docker_apps/{service} → volumes',9,GRAY)
    ctrs=[
        (0.8,6.5,'npm','jc21/nginx-proxy-manager',':80 :443 :81',BLUE),
        (4.0,6.5,'n8n','n8nio/n8n',':5678',GREEN),
        (7.2,6.5,'forgejo','forgejo/forgejo:7',':3000',YELLOW),
        (10.4,6.5,'netlockrmm','netlock/rmm',':80',PURPLE),
        (13.6,6.5,'netlockrmm-web','netlock/rmm-web',':80',PURPLE),
        (0.8,4.0,'postgres','postgres:16',':5432',RED),
        (4.0,4.0,'pgadmin','dpage/pgadmin4',':80',RED),
        (7.2,4.0,'mysql','mysql:8.0',':3306',ORANGE),
        (10.4,4.0,'phpmyadmin','phpmyadmin:latest',':80',ORANGE),
        (5.6,1.8,'landing','nginx:alpine',':80',PINK),
    ]
    for x,y,nm,img,port,col in ctrs:
        bx(ax,x,y,2.8,1.8,b=col)
        tx(ax,x+1.4,y+1.45,nm,8,col,True)
        tx(ax,x+1.4,y+1.1,img,6.5,GRAY)
        tx(ax,x+1.4,y+0.7,port,8,WHITE)
        tx(ax,x+1.4,y+0.35,'172.20.x.x',7,GRAY)
    tx(ax,8,0.8,'Ubuntu 24.04.4 LTS  •  Docker 27+  •  /docker_apps  •  IPsec: xfrm0 172.20.10.1',8,GRAY)
    save(fig,'04_docker_network.png')

# ── Diagram 5: URL Routing ───────────────────────────────────────────────────
def d5():
    fig,ax=sfig(16,10); ax.set_xlim(0,16); ax.set_ylim(0,10)
    tx(ax,8,9.5,'URL Routing Map — rmmx.xinle.biz via Nginx Proxy Manager',13,PINK,True)
    bx(ax,0.3,1.0,3.2,7.5,c='#0f0f1a',b=BLUE,lw=2)
    tx(ax,1.9,8.2,'Nginx Proxy\nManager',10,BLUE,True)
    tx(ax,1.9,7.5,'rmmx.xinle.biz',8,WHITE)
    tx(ax,1.9,7.1,':80 / :443',7.5,GRAY)
    tx(ax,1.9,6.6,"Let's Encrypt\nSSL Auto",7.5,GREEN)
    routes=[
        ('/ (root)','301 → /home','—',GRAY,8.0),
        ('/home','Landing Page (nginx)',':80',PINK,7.0),
        ('/rmm','NetLock RMM',':80',PURPLE,6.0),
        ('/npm','NPM Admin Panel',':81',BLUE,5.0),
        ('/n8n','n8n (WebSocket)',':5678',GREEN,4.0),
        ('/git','Forgejo',':3000',YELLOW,3.0),
        ('/pgdba','pgAdmin 4',':80',RED,2.0),
        ('/dba','phpMyAdmin',':80',ORANGE,1.2),
    ]
    for path,name,port,col,y in routes:
        bx(ax,4.0,y-0.3,2.8,0.75,b=col)
        tx(ax,5.4,y+0.08,path,9,col,True)
        ar(ax,3.5,y+0.08,4.0,y+0.08,col,1.5)
        bx(ax,7.5,y-0.3,8.0,0.75,c='#0d1117',b=col)
        tx(ax,11.5,y+0.08,f'{name}  →  container{port}',9,col,ha='center')
        ar(ax,6.8,y+0.08,7.5,y+0.08,GRAY,1.2)
    save(fig,'05_url_routing.png')

# ── Diagram 6: Cloudflare DNS ────────────────────────────────────────────────
def d6():
    fig,ax=sfig(16,8); ax.set_xlim(0,16); ax.set_ylim(0,8)
    tx(ax,8,7.5,'Cloudflare DNS Configuration — xinle.biz',13,PINK,True)
    hdrs=['Type','Name','Content','Proxy','TTL','Purpose']
    cxs=[0.4,1.8,3.5,7.0,9.2,10.5]
    bx(ax,0.3,6.5,15.4,0.8,c='#1a1a2e',b=PINK)
    for i,h in enumerate(hdrs):
        tx(ax,cxs[i],6.9,h,9,PINK,True,ha='left')
    rows=[
        ('A','rmm','184.105.7.78','🔘 DNS Only (Grey)','Auto','REQUIRED — initial setup / SSL issue',GREEN),
        ('A','rmm','184.105.7.78','🟠 Proxied (Orange)','Auto','Optional — after SSL certs issued',YELLOW),
        ('CNAME','www','rmmx.xinle.biz','🟠 Proxied','Auto','www redirect',BLUE),
        ('A','@','184.105.7.78','🟠 Proxied','Auto','Root domain apex',ORANGE),
    ]
    for i,(t,n,c,p,ttl,pur,col) in enumerate(rows):
        y=5.5-i*0.9
        bx(ax,0.3,y-0.3,15.4,0.75,b=BORDER)
        for j,v in enumerate([t,n,c,p,ttl,pur]):
            tx(ax,cxs[j],y+0.08,v,8,col if j==3 else WHITE,ha='left')
    bx(ax,0.3,0.3,15.4,1.0,c='#1a0a0a',b=ORANGE)
    tx(ax,8,0.9,'⚠  Cloudflare proxy MUST be DNS-only (grey cloud) when running 01_master_setup.sh',9,ORANGE,True)
    tx(ax,8,0.55,"Let's Encrypt HTTP-01 challenge requires direct access to port 80 on 184.105.7.78",8,GRAY)
    save(fig,'06_cloudflare_dns.png')

# ── Diagram 7: UDM Pro Config ────────────────────────────────────────────────
def d7():
    fig,ax=sfig(16,9); ax.set_xlim(0,16); ax.set_ylim(0,9)
    tx(ax,8,8.5,'UDM Pro — Site-to-Site VPN Settings Reference',13,GREEN,True)
    tx(ax,8,8.1,'UniFi Network → Settings → VPN → Site-to-Site VPN → Create New',9,GRAY)
    fields=[
        ('VPN Type','IPsec',WHITE),
        ('IKE Version','IKEv2',GREEN),
        ('Pre-Shared Key','<value printed by 05_setup_ipsec_vpn.sh>',YELLOW),
        ('Remote Host / Peer IP','184.105.7.78  (VPS Public IP)',PINK),
        ('Remote Network','172.20.0.0/16  (Docker subnet)',PINK),
        ('Local Network','10.1.0.0/24  (AI Site LAN)',GREEN),
        ('Encryption','AES-256',BLUE),
        ('Hash / Integrity','SHA-256',BLUE),
        ('DH Group','14  (2048-bit MODP)',BLUE),
        ('PFS (Perfect Forward Secrecy)','Enabled',GREEN),
    ]
    for i,(f,v,col) in enumerate(fields):
        y=7.3-i*0.65
        bx(ax,0.5,y-0.22,5.5,0.55,c='#1a1a2e',b=BORDER)
        tx(ax,3.25,y+0.05,f,9,GRAY,ha='center')
        bx(ax,6.5,y-0.22,9.0,0.55,b=col)
        tx(ax,11.0,y+0.05,v,9,col,True,ha='center')
    bx(ax,0.5,0.3,15.0,1.0,c='#0a1a0a',b=GREEN)
    tx(ax,8,0.85,'Verify: ping 172.20.10.1 from any 10.1.0.x device  |  On VPS: sudo ipsec status',9,GREEN,True)
    tx(ax,8,0.5,'Tunnel IP 172.20.10.1 = VPS tunnel endpoint  |  172.20.0.0/16 = all Docker containers',8,GRAY)
    save(fig,'07_udm_pro_config.png')

if __name__=='__main__':
    print('Generating Xinle 欣乐 infrastructure diagrams...')
    d1(); d2(); d3(); d4(); d5(); d6(); d7()
    print(f'\nAll 7 diagrams saved to: {os.path.abspath(OUT_DIR)}')
