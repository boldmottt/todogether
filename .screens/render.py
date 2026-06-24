#!/usr/bin/env python3
"""todogether 화면 레이아웃을 PNG로 렌더링.
주의: 컴파일된 iOS 앱의 시뮬레이터 캡처가 아니라, SwiftUI 뷰 코드의 레이아웃을
재현한 '렌더링'이다(Linux엔 Xcode/시뮬레이터가 없음). 시각 검증 대체물.
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
S = 2  # 2x 스케일
W, H = 390 * S, 844 * S

KR = "/usr/share/fonts/truetype/nanum/NanumSquareRoundR.ttf"
KRB = "/usr/share/fonts/truetype/nanum/NanumSquareRoundB.ttf"
EMOJI = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"

def f(size, bold=False):
    return ImageFont.truetype(KRB if bold else KR, int(size * S))

# 이모지 색상 폰트 (NotoColorEmoji는 109px 고정 → 그려서 축소)
try:
    EM = ImageFont.truetype(EMOJI, 109)
    _emoji_ok = True
except Exception:
    _emoji_ok = False

# 기존 시스템 색상 (기존 화면용)
INK = (20, 20, 24)
SUB = (140, 142, 150)
LINE = (228, 230, 235)
BG = (242, 243, 247)
CARD = (255, 255, 255)
BLUE = (10, 122, 255)
GREEN = (52, 199, 89)
RED = (255, 59, 48)
ORANGE = (255, 149, 0)
PURPLE = (94, 92, 230)

# 손그림 노트패드 테마 — 흰 종이 + 검정 잉크
SK_PAPER  = (247, 247, 245)   # #F7F7F5 흰 종이
SK_CARD   = (255, 255, 255)   # 순백 카드
SK_INK    = (26,  26,  24)    # #1A1A18 잉크 블랙
SK_SOFT   = (85,  85,  80)    # #555550 흐린 잉크
SK_RULE   = (200, 200, 200)   # 연한 줄선
SK_ACCENT = (26,  26,  24)    # 강조도 잉크
SK_SAGE   = (26,  26,  24)    # 체크도 잉크
SK_SAND   = (170, 170, 170)   # 잠금 회색
SK_FADE   = (170, 170, 170)   # 완료된 항목

def emoji_img(ch, px):
    """컬러 이모지 한 글자를 px 크기 RGBA 이미지로."""
    if not _emoji_ok:
        return None
    try:
        tmp = Image.new("RGBA", (140, 140), (0, 0, 0, 0))
        d = ImageDraw.Draw(tmp)
        d.text((0, 0), ch, font=EM, embedded_color=True)
        bbox = tmp.getbbox()
        if not bbox:
            return None
        cropped = tmp.crop(bbox)
        return cropped.resize((px, px), Image.LANCZOS)
    except Exception:
        return None

def rounded(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

def base(status_dark=False):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    # 상태바
    col = INK if not status_dark else (255, 255, 255)
    d.text((20 * S, 14 * S), "9:41", font=f(14, True), fill=col)
    # 우측 배터리/신호 (간략)
    d.text((W - 70 * S, 14 * S), "▮▮▮ ▮", font=f(12), fill=col)
    return img, d

def navbar(d, title, left=None, right_icons=()):
    d.text((W/2, 70 * S), title, font=f(17, True), fill=INK, anchor="mm")
    if left:
        d.text((20 * S, 70 * S), left, font=f(15), fill=BLUE, anchor="lm")
    x = W - 20 * S
    for ic in right_icons:
        d.text((x, 70 * S), ic, font=f(20), fill=BLUE, anchor="rm")
        x -= 34 * S

def paste_emoji(img, ch, xy, px):
    e = emoji_img(ch, px)
    if e:
        img.paste(e, (int(xy[0]), int(xy[1])), e)
        return True
    return False

def tabbar(d, active=0):
    items = [("□", "투두"), ("▦", "캘린더"), ("◎", "공유방"), ("▤", "템플릿"), ("⚙", "설정")]
    y = H - 60 * S
    d.line([(0, y - 6 * S), (W, y - 6 * S)], fill=LINE, width=S)
    n = len(items)
    for i, (ic, label) in enumerate(items):
        cx = W * (i + 0.5) / n
        col = BLUE if i == active else SUB
        d.text((cx, y + 6 * S), ic, font=f(18), fill=col, anchor="mm")
        d.text((cx, y + 28 * S), label, font=f(10), fill=col, anchor="mm")

# ---- 손그림 잉크 헬퍼 ----

def seeded_rng(seed):
    state = (seed * 2654435761) & 0xFFFFFFFFFFFFFFFF
    state = (state * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    state = (state * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    def next_val():
        nonlocal state
        state = (state * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return (state >> 33) / (1 << 31)
    return next_val

def blend(c1, c2, t):
    return tuple(int(c1[i]*(1-t) + c2[i]*t) for i in range(3))

def draw_ink_line(d, y_base, width, seed, thickness=1.4, alpha=0.22):
    rng = seeded_rng(seed)
    a = alpha + rng() * 0.10
    lw = max(2, int((thickness + rng() * 0.6) * S))
    ink = blend(SK_PAPER, SK_INK, a)
    seg_w = 22 * S
    segs = int(width / seg_w) + 2
    pts = []
    for s in range(segs):
        x = s * seg_w
        dy = (rng() * 2 - 1) * 1.8 * S
        pts.append((x, y_base + dy))
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i+1]], fill=ink, width=lw)

def draw_wobbly_square(d, x, y, size, seed, done=False, locked=False):
    rng = seeded_rng(seed)
    j = lambda mag=1.5: (rng() * 2 - 1) * mag * S
    s = size
    tl = (x + j(1.0),     y + j(1.0))
    tr = (x + s + j(1.0), y + j(1.0))
    br = (x + s + j(1.0), y + s + j(1.0))
    bl = (x + j(1.0),     y + s + j(1.0))
    col = SK_FADE if (done or locked) else SK_INK
    lw  = max(2, int((1.8 + rng() * 0.6) * S))
    def mid(a, b): return ((a[0]+b[0])/2 + j(0.8), (a[1]+b[1])/2 + j(0.8))
    sides = [(tl, tr), (tr, br), (br, bl), (bl, tl)]
    for a, b in sides:
        m = mid(a, b)
        d.line([a, m, b], fill=col, width=lw, joint="curve")

def draw_checkmark(d, x, y, size, seed):
    rng = seeded_rng(seed + 9999)
    style = int(rng() * 4)
    j = lambda: (rng() * 2 - 1) * 1.8 * S
    s = size
    if style == 0:
        p1 = (x+s*0.18+j(), y+s*0.52+j()); p2 = (x+s*0.42+j(), y+s*0.74+j()); p3 = (x+s*0.82+j(), y+s*0.26+j())
    elif style == 1:
        p1 = (x+s*0.16+j(), y+s*0.55+j()); p2 = (x+s*0.40+j(), y+s*0.72+j()); p3 = (x+s*0.84+j(), y+s*0.24+j())
    elif style == 2:
        p1 = (x+s*0.20+j(), y+s*0.48+j()); p2 = (x+s*0.38+j(), y+s*0.70+j()); p3 = (x+s*0.80+j(), y+s*0.22+j())
    else:
        p1 = (x+s*0.22+j(), y+s*0.50+j()); p2 = (x+s*0.42+j(), y+s*0.68+j()); p3 = (x+s*0.80+j(), y+s*0.28+j())
    lw = max(2, int((2.2 + rng() * 0.4) * S))
    d.line([p1, p2, p3], fill=SK_INK, width=lw, joint="curve")

# ---------------- 1. Todo List ----------------
def sk_base():
    """새 스타일 베이스 — 흰 종이 + 줄선"""
    img = Image.new("RGB", (W, H), SK_PAPER)
    d = ImageDraw.Draw(img)
    for i in range(50):
        draw_ink_line(d, (52 + i * 44) * S, W, seed=i*137+17, thickness=1.3, alpha=0.16)
    d.text((20*S, 14*S), "9:41", font=f(14,True), fill=SK_INK)
    d.text((W-70*S, 14*S), "▮▮▮ ▮", font=f(12), fill=SK_INK)
    return img, d

def sk_navbar(d, title, left=None, right=None):
    d.rectangle([(0,0),(W,90*S)], fill=SK_PAPER)
    draw_ink_line(d, 90*S, W, seed=9001, thickness=2.0, alpha=0.35)
    d.text((W/2, 62*S), title, font=f(19,True), fill=SK_INK, anchor="mm")
    if left:
        d.text((20*S, 62*S), left, font=f(16), fill=SK_INK, anchor="lm")
    if right:
        d.text((W-20*S, 62*S), right, font=f(20,True), fill=SK_INK, anchor="rm")

def sk_tabbar(d, active=0):
    d.rectangle([(0, H-80*S),(W,H)], fill=SK_PAPER)
    draw_ink_line(d, H-80*S, W, seed=8888, thickness=2.0, alpha=0.35)
    items = [("☐","투두"),("▦","캘린더"),("◎","공유방"),("▤","템플릿"),("⚙","설정")]
    for i,(ic,lb) in enumerate(items):
        cx = int(W*(i+0.5)/5)
        col = SK_INK if i==active else SK_SOFT
        fw = True if i==active else False
        d.text((cx, H-52*S), ic, font=f(19,fw), fill=col, anchor="mm")
        d.text((cx, H-28*S), lb, font=f(10,fw), fill=col, anchor="mm")

def sk_section_header(d, text, y):
    d.text((24*S, y), text, font=f(11,True), fill=SK_SOFT)

def sk_divider(d, y, x0=20, x1=None):
    draw_ink_line(d, y*S, W if x1 is None else (x1-x0)*S, seed=int(y), thickness=0.9, alpha=0.13)

def sk_row_checkbox(d, x, y, size, seed, done=False, locked=False):
    draw_wobbly_square(d, x, y, size, seed, done=done, locked=locked)
    if done:
        draw_checkmark(d, x, y, size, seed)
    elif locked:
        m = int(size*0.28)
        xi, yi = int(x), int(y)
        sz = int(size)
        d.line([(xi+m,yi+m),(xi+sz-m,yi+sz-m)], fill=SK_FADE, width=max(1,int(1.5*S)))
        d.line([(xi+sz-m,yi+m),(xi+m,yi+sz-m)], fill=SK_FADE, width=max(1,int(1.5*S)))

# 잉크 토글 (흑백 스타일)
def sk_toggle(d, x, y, on=True):
    w, h = int(46*S), int(26*S)
    col = SK_INK if on else SK_FADE
    rng = seeded_rng(int(x)+int(y))
    j = lambda: (rng()*2-1)*0.8*S
    # 삐뚤한 pill
    d.rounded_rectangle([x, y, x+w, y+h], radius=h//2, fill=col)
    kx = x+w-h//2-2 if on else x+h//2+2
    d.ellipse([kx-h//2+3, y+3, kx+h//2-3, y+h-3], fill=SK_PAPER)

# ---------------- 1. Todo List ----------------
def todo_list():
    img, d = sk_base()
    sk_navbar(d, "투두", right="+")
    y = 102 * S
    rows = [
        (1001, False, "장보기",       "오늘",  None,      False),
        (2002, True,  "요리하기",      None,    None,      False),
        (3003, False, "분리수거",      "내일",  None,      False),
        (4004, False, "운동 30분",     "오늘",  "↺ 매일", False),
        (5005, False, "팀 미팅 참석",  "어제",  None,      True),
    ]
    cb = int(20*S); row_h = int(56*S)
    for seed, locked, title, date, badge, done in rows:
        cy2 = int(y + row_h//2)
        if done:
            d.rectangle([(0,y),(W,y+row_h)], fill=blend(SK_PAPER,SK_INK,0.04))
        sk_row_checkbox(d, int(20*S), int(y+(row_h-cb)//2), cb, seed, done=done, locked=locked)
        tx = int(52*S); ty = int(y+row_h//2-9*S)
        col = SK_FADE if (done or locked) else SK_INK
        d.text((tx, ty), title, font=f(15, not done and not locked), fill=col)
        if done:
            tw = len(title)*8*S
            d.line([(tx, ty+10*S),(tx+tw, ty+10*S)], fill=SK_FADE, width=max(1,int(S)))
        by2 = int(y+row_h//2+10*S)
        bx = tx
        if date:
            d.text((bx, by2), date, font=f(10), fill=SK_SOFT)
            bx += int((len(date)*6+8)*S)
        if badge:
            d.text((bx, by2), badge, font=f(10), fill=SK_SOFT)
        draw_ink_line(d, y+row_h, W, seed=seed+1, thickness=0.9, alpha=0.12)
        y += row_h

    y += 8*S
    sk_section_header(d, "완료됨  ·  최근 7일", y)
    sk_tabbar(d, 0)
    img.save(os.path.join(OUT, "01_todo_list.png"))

# ---------------- 2. Todo Detail ----------------
def todo_detail():
    img, d = sk_base()
    sk_navbar(d, "할 일", left="‹")
    y = 102 * S

    def ink_section(lbl, h):
        nonlocal y
        if lbl:
            sk_section_header(d, lbl, y)
            y += 22*S
        draw_ink_line(d, y, W, seed=int(y), thickness=1.8, alpha=0.32)
        y += int(h*S)
        draw_ink_line(d, y, W, seed=int(y)+1, thickness=1.8, alpha=0.32)
        y += 20*S

    # 제목
    d.text((24*S, y+10*S), "요리하기", font=f(20,True), fill=SK_INK)
    draw_ink_line(d, y+44*S, W, seed=101, thickness=1.6, alpha=0.28)
    d.text((24*S, y+52*S), "재료 손질부터 시작", font=f(14), fill=SK_SOFT)
    y += 88*S

    # 날짜
    sk_section_header(d, "마감", y); y += 22*S
    d.text((24*S, y+10*S), "날짜 지정", font=f(14), fill=SK_INK)
    sk_toggle(d, int(W-70*S), int(y+8*S), on=True)
    draw_ink_line(d, y+42*S, W, seed=201, thickness=1.0, alpha=0.18)
    d.text((24*S, y+52*S), "마감일", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+52*S), "6월 25일", font=f(14), fill=SK_INK, anchor="rm")
    y += 90*S

    # 반복
    sk_section_header(d, "반복", y); y += 22*S
    d.text((24*S, y+12*S), "↻ 반복", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+12*S), "매주 월·수·금", font=f(14), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+42*S, W, seed=301, thickness=1.0, alpha=0.18)
    y += 60*S

    # 선행 조건
    sk_section_header(d, "이 일을 하기 전에", y); y += 22*S
    draw_ink_line(d, y, W, seed=401, thickness=1.8, alpha=0.32)
    y += 10*S
    seed_p = 6001
    draw_wobbly_square(d, int(24*S), int(y+6*S), int(20*S), seed_p, done=True)
    draw_checkmark(d, int(24*S), int(y+6*S), int(20*S), seed_p)
    d.text((int(54*S), int(y+8*S)), "장보기", font=f(14), fill=SK_FADE)
    draw_ink_line(d, y+40*S, W, seed=402, thickness=0.9, alpha=0.14)
    y += 50*S
    d.text((24*S, y+10*S), "+ 선행 조건 추가", font=f(14), fill=SK_INK)
    draw_ink_line(d, y+40*S, W, seed=403, thickness=1.8, alpha=0.32)
    y += 55*S
    d.text((24*S, y), "선행 조건이 완료되면 자동으로 활성화돼요", font=f(11), fill=SK_SOFT)

    img.save(os.path.join(OUT, "02_todo_detail.png"))

# ---------------- 3. Calendar ----------------
def calendar():
    img, d = sk_base()
    sk_navbar(d, "캘린더")
    y = int(100*S)
    days = ["일","월","화","수","목","금","토"]
    nums = [22,23,24,25,26,27,28]
    cellw = W/7
    for i in range(7):
        cx = cellw*(i+0.5)
        d.text((cx, y+6*S), days[i], font=f(11), fill=SK_SOFT, anchor="mm")
        sel = (i==2)
        if sel:
            # 손그림 원 표시
            draw_wobbly_square(d, int(cx-12*S), int(y+20*S), int(26*S), 9900+i,
                               done=False, locked=False)
        col = SK_INK if sel else SK_SOFT
        d.text((cx, y+34*S), str(nums[i]), font=f(14,sel), fill=col, anchor="mm")
        # 점
        if i in [1,2,3,5]:
            d.ellipse((cx-3*S, y+54*S, cx+3*S, y+60*S), fill=SK_SOFT)
    y += 76*S
    draw_ink_line(d, y, W, seed=5001, thickness=2.0, alpha=0.30)
    y += 14*S

    def feed_row(title, items):
        nonlocal y
        sk_section_header(d, title, y); y += 22*S
        for seed, label, date, overdue in items:
            cb_y = int(y+(44*S-20*S)//2)
            sk_row_checkbox(d, int(20*S), cb_y, int(20*S), seed)
            d.text((int(50*S), int(y+10*S)), label, font=f(14,True), fill=SK_INK)
            d.text((int(50*S), int(y+30*S)), date, font=f(10), fill=SK_ACCENT if overdue else SK_SOFT)
            draw_ink_line(d, y+44*S, W, seed=seed+1, thickness=0.9, alpha=0.12)
            y += 44*S
        y += 10*S

    feed_row("마감 지남", [(7001,"월세 이체","5월 28일",True)])
    feed_row("오늘",       [(7002,"장보기","오늘",False),(7003,"운동하기","오늘",False)])
    feed_row("내일",       [(7004,"분리수거","내일",False)])

    sk_tabbar(d, 1)
    img.save(os.path.join(OUT, "03_calendar.png"))

# ---------------- 4. Widget ----------------
def widget():
    img = Image.new("RGB", (W, H), SK_PAPER)
    d = ImageDraw.Draw(img)
    for i in range(50):
        draw_ink_line(d, (52+i*44)*S, W, seed=i*137+17, thickness=1.3, alpha=0.13)
    d.text((20*S, 14*S), "9:41", font=f(14,True), fill=SK_INK)

    mx, my = int(24*S), int(160*S)
    mw, mh = W-48*S, int(230*S)
    # 손그림 카드
    d.rectangle([mx, my, mx+mw, my+mh], fill=SK_CARD)
    # 굵은 테두리
    rng_w = seeded_rng(42)
    j = lambda: (rng_w()*2-1)*1.2*S
    corners = [(mx+j(),my+j()),(mx+mw+j(),my+j()),(mx+mw+j(),my+mh+j()),(mx+j(),my+mh+j())]
    for i in range(4):
        a, b = corners[i], corners[(i+1)%4]
        mid = ((a[0]+b[0])/2+j(), (a[1]+b[1])/2+j())
        d.line([a,mid,b], fill=SK_INK, width=max(2,int(2.2*S)), joint="curve")

    d.text((mx+20*S, my+16*S), "오늘 할 일", font=f(13,True), fill=SK_SOFT)
    draw_ink_line(d, my+38*S, mw, seed=5555, thickness=1.5, alpha=0.25)
    rows_w = [("장보기",False,8001),("요리하기",False,8002),("운동하기",True,8003),("분리수거",False,8004)]
    ry = my+48*S
    cb = int(18*S)
    for title, done, seed in rows_w:
        sk_row_checkbox(d, int(mx+16*S), int(ry), cb, seed, done=done)
        d.text((int(mx+46*S), int(ry+1*S)), title, font=f(13), fill=SK_FADE if done else SK_INK)
        ry += int(40*S)

    d.text((W/2, my+mh+28*S), "todogether · 탭하면 완료", font=f(11), fill=SK_SOFT, anchor="mm")
    img.save(os.path.join(OUT, "04_widget.png"))

# ---------------- 5. Onboarding ----------------
def onboarding():
    img, d = sk_base()
    # 큰 손그림 일러스트 영역
    cx = W/2
    # 스틱 피겨 2명 (참고 이미지 스타일)
    def stick_person(bx, by, size, seed):
        rng = seeded_rng(seed)
        j = lambda m=1.0: (rng()*2-1)*m*S
        s = size*S
        # 머리
        d.ellipse([bx-s*0.18+j(), by+j(), bx+s*0.18+j(), by+s*0.36+j()],
                  outline=SK_INK, width=max(2,int(2.0*S)))
        # 몸
        d.line([(bx+j(), by+s*0.36+j()), (bx+j(), by+s*0.72+j())],
               fill=SK_INK, width=max(2,int(2.0*S)))
        # 팔
        d.line([(bx-s*0.22+j(), by+s*0.5+j()), (bx+s*0.22+j(), by+s*0.5+j())],
               fill=SK_INK, width=max(2,int(1.8*S)))
        # 다리
        d.line([(bx+j(), by+s*0.72+j()), (bx-s*0.18+j(), by+s+j())],
               fill=SK_INK, width=max(2,int(1.8*S)))
        d.line([(bx+j(), by+s*0.72+j()), (bx+s*0.18+j(), by+s+j())],
               fill=SK_INK, width=max(2,int(1.8*S)))

    stick_person(int(W/2-40*S), int(200*S), 70, 3001)
    stick_person(int(W/2+40*S), int(200*S), 70, 3002)
    # 하트
    d.text((int(W/2), int(280*S)), "♡", font=f(28,True), fill=SK_INK, anchor="mm")

    d.text((cx, 370*S), "함께 만드는 할 일", font=f(22,True), fill=SK_INK, anchor="mm")
    d.text((cx, 408*S), "가족·친구와 공유방을 만들어", font=f(14), fill=SK_SOFT, anchor="mm")
    d.text((cx, 430*S), "할 일을 나눠요.", font=f(14), fill=SK_SOFT, anchor="mm")

    # 페이지 닷 (삐뚤한 원)
    for i in range(3):
        dcx = int(cx - 16*S + i*16*S)
        if i == 1:
            draw_wobbly_square(d, dcx-5*S, int(500*S), int(10*S), 4000+i)
        else:
            d.ellipse([dcx-4*S, 501*S, dcx+4*S, 509*S], outline=SK_SOFT, width=max(1,int(1.5*S)))

    # 버튼 (손그림 사각형)
    bx, by2 = int(40*S), int(640*S)
    bw, bh = W-80*S, int(52*S)
    rng_b = seeded_rng(5001)
    j2 = lambda: (rng_b()*2-1)*1.5*S
    corners_b = [(bx+j2(),by2+j2()),(bx+bw+j2(),by2+j2()),
                 (bx+bw+j2(),by2+bh+j2()),(bx+j2(),by2+bh+j2())]
    d.polygon(corners_b, fill=SK_INK)
    d.text((cx, by2+bh//2), "시작하기", font=f(17,True), fill=SK_PAPER, anchor="mm")
    d.text((cx, by2+bh+30*S), "로그인 없이 시작", font=f(13), fill=SK_SOFT, anchor="mm")
    img.save(os.path.join(OUT, "05_onboarding.png"))

# ---------------- 6. Space Detail ----------------
def space_detail():
    img, d = sk_base()
    sk_navbar(d, "우리집", left="‹")
    y = 102*S

    d.text((24*S, y+10*S), "우리집", font=f(20,True), fill=SK_INK)
    draw_ink_line(d, y+40*S, W, seed=6001, thickness=1.8, alpha=0.30)
    y += 56*S

    sk_section_header(d, "멤버", y); y += 22*S
    members = [("나","소유자",6101), ("민지","멤버",6102), ("지호","멤버",6103)]
    for name, role, seed in members:
        # 아바타 손그림 원
        draw_wobbly_square(d, int(20*S), int(y+8*S), int(32*S), seed)
        d.text((int(62*S), int(y+10*S)), name, font=f(14,True), fill=SK_INK)
        d.text((int(62*S), int(y+28*S)), role, font=f(11), fill=SK_SOFT)
        draw_ink_line(d, y+48*S, W, seed=seed+1, thickness=0.9, alpha=0.12)
        y += 50*S
    d.text((24*S, y+12*S), "+ 사람 초대하기", font=f(14), fill=SK_INK)
    draw_ink_line(d, y+44*S, W, seed=6199, thickness=1.8, alpha=0.28)
    y += 60*S

    sk_section_header(d, "초대 코드", y); y += 22*S
    draw_ink_line(d, y, W, seed=6200, thickness=1.8, alpha=0.30)
    y += 12*S
    d.text((28*S, y+8*S), "HJK", font=f(30,True), fill=SK_INK)
    d.text((int(W/2), y+10*S), "—", font=f(24), fill=SK_SOFT, anchor="mm")
    d.text((W/2+20*S, y+8*S), "9NP", font=f(30,True), fill=SK_INK)
    d.text((W-28*S, y+16*S), "⧉", font=f(20), fill=SK_INK, anchor="rm")
    y += 52*S
    d.text((24*S, y), "이 코드를 멤버에게 알려주세요.", font=f(12), fill=SK_SOFT)
    draw_ink_line(d, y+36*S, W, seed=6201, thickness=1.8, alpha=0.28)
    y += 48*S

    # 삭제 (손그림)
    d.text((24*S, y+14*S), "공유방 삭제", font=f(14), fill=SK_SOFT)
    img.save(os.path.join(OUT, "06_space_detail.png"))

# ---------------- 7. Reaction ----------------
def reaction():
    img, d = sk_base()
    sk_navbar(d, "투두", right="+")
    y = int(150*S)

    seed_r = 7001
    cb = int(20*S)
    row_h = int(56*S)
    draw_wobbly_square(d, int(20*S), int(y+(row_h-cb)//2), cb, seed_r, done=True)
    draw_checkmark(d, int(20*S), int(y+(row_h-cb)//2), cb, seed_r)
    d.text((int(52*S), int(y+14*S)), "설거지", font=f(15), fill=SK_FADE)
    d.text((W-24*S, int(y+14*S)), "민지", font=f(12), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+row_h, W, seed=7002, thickness=0.9, alpha=0.14)
    y += row_h + 16*S

    # 반응 버블 (손그림 pill)
    bh = int(58*S); bw = int(320*S); bx = int((W-bw)//2)
    rng_r = seeded_rng(7003)
    jr = lambda: (rng_r()*2-1)*1.2*S
    pts = [(bx+jr(),y+jr()),(bx+bw+jr(),y+jr()),
           (bx+bw+jr(),y+bh+jr()),(bx+jr(),y+bh+jr())]
    d.polygon(pts, fill=SK_CARD)
    draw_ink_line(d, y, bw, seed=7010, thickness=1.8, alpha=0.30)
    draw_ink_line(d, y+bh, bw, seed=7011, thickness=1.8, alpha=0.30)

    emojis = ["👍","❤️","🎉","💪","😂","🙏"]
    ex = bx + 14*S
    for ch in emojis:
        if not paste_emoji(img, ch, (ex, y+14*S), int(30*S)):
            d.text((ex+15*S, y+29*S), ch, font=f(18), fill=SK_INK, anchor="mm")
        ex += int(48*S)

    d.text((W//2, int(y+bh+30*S)), "완료된 공유 할 일을 길게 눌러 반응", font=f(12), fill=SK_SOFT, anchor="mm")
    sk_tabbar(d, 0)
    img.save(os.path.join(OUT, "07_reaction.png"))

# ---------------- 8. Notif Settings ----------------
def notif_settings():
    img, d = sk_base()
    sk_navbar(d, "알림", left="‹")
    y = 102*S
    sk_section_header(d, "알림 종류", y); y += 22*S
    draw_ink_line(d, y, W, seed=8001, thickness=1.8, alpha=0.30)
    toggles = [("마감 알림",True),("연계 해제",True),("공유방 완료",True),("콕 찌르기",True),("반응 알림",False)]
    for label, on in toggles:
        y += 6*S
        d.text((24*S, y+8*S), label, font=f(14), fill=SK_INK)
        sk_toggle(d, int(W-70*S), int(y+6*S), on=on)
        draw_ink_line(d, y+38*S, W, seed=int(y), thickness=0.9, alpha=0.12)
        y += 44*S
    draw_ink_line(d, y, W, seed=8099, thickness=1.8, alpha=0.30)
    y += 20*S

    sk_section_header(d, "방해 금지", y); y += 22*S
    draw_ink_line(d, y, W, seed=8101, thickness=1.8, alpha=0.30)
    y += 10*S
    d.text((24*S, y+8*S), "방해 금지 시간", font=f(14), fill=SK_INK)
    sk_toggle(d, int(W-70*S), int(y+6*S), on=True)
    draw_ink_line(d, y+38*S, W, seed=8102, thickness=0.9, alpha=0.12)
    y += 48*S
    d.text((24*S, y+8*S), "시작", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+8*S), "22시", font=f(14), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=8103, thickness=0.9, alpha=0.12)
    y += 48*S
    d.text((24*S, y+8*S), "종료", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+8*S), "8시", font=f(14), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=8104, thickness=1.8, alpha=0.28)
    y += 52*S
    d.text((24*S, y), "자정을 넘는 구간(22시~8시)도 설정할 수 있어요", font=f(11), fill=SK_SOFT)
    img.save(os.path.join(OUT, "08_notif_settings.png"))

# ---------------- 9. Settings ----------------
def settings():
    img, d = sk_base()
    sk_navbar(d, "설정")
    y = 102*S

    # 계정
    sk_section_header(d, "계정", y); y += 22*S
    draw_ink_line(d, y, W, seed=9101, thickness=1.8, alpha=0.30)
    y += 10*S
    # 아바타 손그림
    draw_wobbly_square(d, int(20*S), int(y+4*S), int(36*S), 9001)
    d.text((int(66*S), int(y+6*S)), "김민준", font=f(15,True), fill=SK_INK)
    d.text((int(66*S), int(y+26*S)), "Apple로 로그인됨", font=f(11), fill=SK_SOFT)
    draw_ink_line(d, y+50*S, W, seed=9102, thickness=1.8, alpha=0.28)
    y += 62*S

    sk_section_header(d, "보안", y); y += 22*S
    draw_ink_line(d, y, W, seed=9201, thickness=1.8, alpha=0.30)
    y += 10*S
    d.text((24*S, y+8*S), "Face ID / Touch ID 잠금", font=f(14), fill=SK_INK)
    sk_toggle(d, int(W-70*S), int(y+6*S), on=True)
    draw_ink_line(d, y+38*S, W, seed=9202, thickness=0.9, alpha=0.12)
    y += 48*S
    d.text((24*S, y), "앱 실행 시 생체 인증이 필요합니다.", font=f(11), fill=SK_SOFT)
    draw_ink_line(d, y+20*S, W, seed=9203, thickness=1.8, alpha=0.28)
    y += 36*S

    sk_section_header(d, "알림", y); y += 22*S
    draw_ink_line(d, y, W, seed=9301, thickness=1.8, alpha=0.30)
    y += 10*S
    d.text((24*S, y+8*S), "알림 설정", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+10*S), "›", font=f(18), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=9302, thickness=1.8, alpha=0.28)
    y += 54*S

    sk_section_header(d, "앱 정보", y); y += 22*S
    draw_ink_line(d, y, W, seed=9401, thickness=1.8, alpha=0.30)
    y += 10*S
    d.text((24*S, y+8*S), "버전", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+10*S), "1.0.0", font=f(14), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=9402, thickness=1.8, alpha=0.28)

    sk_tabbar(d, 4)
    img.save(os.path.join(OUT, "09_settings.png"))

# ---------------- 10. Todo Claiming ----------------
def todo_list_claiming():
    img, d = sk_base()
    sk_navbar(d, "우리집", left="‹", right="+")
    y = 102*S
    rows = [
        (1001, False, "설거지 하기",   "오늘",  False, False),
        (2002, False, "쓰레기 버리기", "내일",  True,  False),   # 미배정
        (3003, True,  "요리하기",      None,    False, False),
    ]
    cb = int(20*S); row_h = int(56*S)
    for idx, (seed, locked, title, date, unassigned, done) in enumerate(rows):
        if idx == 1:
            # 스와이프된 행 (오른쪽 액션 노출)
            d.rectangle([(0,y),(W,y+row_h)], fill=blend(SK_PAPER,SK_INK,0.07))
            d.text((W-int(60*S), int(y+row_h//2)), "내가\n할게", font=f(12,True),
                   fill=SK_INK, anchor="mm")
            sk_row_checkbox(d, int(20*S), int(y+(row_h-cb)//2), cb, seed, locked=locked)
        else:
            sk_row_checkbox(d, int(20*S), int(y+(row_h-cb)//2), cb, seed, done=done, locked=locked)
        col = SK_FADE if locked else SK_INK
        d.text((int(52*S), int(y+row_h//2-9*S)), title, font=f(15,True), fill=col)
        by2 = int(y+row_h//2+10*S)
        if date:
            d.text((int(52*S), by2), date, font=f(10), fill=SK_SOFT)
        if unassigned:
            bx2 = int(52*S + (len(date)*6+10)*S)
            d.text((bx2, by2), "미배정", font=f(10), fill=SK_INK)
        draw_ink_line(d, y+row_h, W, seed=seed+1, thickness=0.9, alpha=0.12)
        y += row_h
    sk_tabbar(d, 0)
    img.save(os.path.join(OUT, "10_todo_claiming.png"))

# ---------------- 11. Add Todo NLP ----------------
def add_todo_nlp():
    img, d = sk_base()
    sk_navbar(d, "새 할 일", left="취소", right="추가")
    y = 102*S
    draw_ink_line(d, y, W, seed=1101, thickness=1.8, alpha=0.30)
    y += 12*S
    d.text((24*S, y+8*S), "다음주 월요일 팀 미팅", font=f(16), fill=SK_INK)
    draw_ink_line(d, y+38*S, W, seed=1102, thickness=0.9, alpha=0.14)
    y += 50*S
    # 파싱 힌트 (손그림 박스)
    hx, hy = int(20*S), int(y)
    hw, hh = W-40*S, int(34*S)
    rng_h = seeded_rng(1103)
    jh = lambda: (rng_h()*2-1)*1.0*S
    d.polygon([(hx+jh(),hy+jh()),(hx+hw+jh(),hy+jh()),
               (hx+hw+jh(),hy+hh+jh()),(hx+jh(),hy+hh+jh())],
              fill=blend(SK_PAPER,SK_INK,0.06))
    d.text((hx+12*S, hy+8*S), "✦ 날짜 인식: 6월 30일 월요일", font=f(12), fill=SK_INK)
    y += hh + 20*S
    draw_ink_line(d, y, W, seed=1104, thickness=1.8, alpha=0.30)
    y += 12*S

    d.text((24*S, y+8*S), "날짜 지정", font=f(14), fill=SK_INK)
    sk_toggle(d, int(W-70*S), int(y+6*S), on=True)
    draw_ink_line(d, y+38*S, W, seed=1105, thickness=0.9, alpha=0.14)
    y += 52*S

    d.text((24*S, y+8*S), "날짜", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+8*S), "2026년 6월 30일", font=f(14), fill=SK_INK, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=1106, thickness=1.8, alpha=0.28)
    y += 56*S

    d.text((24*S, y+8*S), "반복", font=f(14), fill=SK_INK)
    d.text((W-24*S, y+8*S), "안 함", font=f(14), fill=SK_SOFT, anchor="rm")
    draw_ink_line(d, y+38*S, W, seed=1107, thickness=1.8, alpha=0.28)

    img.save(os.path.join(OUT, "11_add_todo_nlp.png"))

# ---------------- 12. Apple Sign In ----------------
def apple_signin():
    img, d = sk_base()
    cx = W/2

    # 손그림 스틱 피겨 + 체크
    stick_y = int(200*S)
    rng_a = seeded_rng(1201)
    j = lambda: (rng_a()*2-1)*1.5*S
    r = int(30*S)
    # 머리
    d.ellipse([cx-r+j(),stick_y+j(),cx+r+j(),stick_y+r*2+j()],
              outline=SK_INK, width=max(2,int(2.2*S)))
    # 몸+팔+다리
    d.line([(cx+j(),stick_y+r*2+j()),(cx+j(),stick_y+r*4+j())], fill=SK_INK, width=max(2,int(2.0*S)))
    d.line([(cx-r*1.2+j(),stick_y+r*2.8+j()),(cx+r*1.2+j(),stick_y+r*2.8+j())], fill=SK_INK, width=max(2,int(2.0*S)))
    d.line([(cx+j(),stick_y+r*4+j()),(cx-r*0.9+j(),stick_y+r*5.5+j())], fill=SK_INK, width=max(2,int(2.0*S)))
    d.line([(cx+j(),stick_y+r*4+j()),(cx+r*0.9+j(),stick_y+r*5.5+j())], fill=SK_INK, width=max(2,int(2.0*S)))
    # 손그림 하트
    d.text((cx, int(stick_y+r*6.5)), "♡", font=f(22,True), fill=SK_INK, anchor="mm")

    d.text((cx, int(400*S)), "todogether", font=f(26,True), fill=SK_INK, anchor="mm")
    d.text((cx, int(436*S)), "함께 만드는 할 일 목록", font=f(14), fill=SK_SOFT, anchor="mm")
    draw_ink_line(d, int(462*S), W, seed=1202, thickness=1.5, alpha=0.25)

    # Apple 로그인 버튼 (손그림 사각형)
    by = int(490*S)
    bw = W - 80*S
    bh = int(52*S)
    bx = int(40*S)
    rng_b = seeded_rng(1203)
    jb = lambda: (rng_b()*2-1)*1.5*S
    d.polygon([(bx+jb(),by+jb()),(bx+bw+jb(),by+jb()),
               (bx+bw+jb(),by+bh+jb()),(bx+jb(),by+bh+jb())], fill=SK_INK)
    d.text((cx, by+bh//2), "Apple로 로그인", font=f(16,True), fill=SK_PAPER, anchor="mm")

    draw_ink_line(d, int(by+bh+20*S), W, seed=1204, thickness=1.0, alpha=0.18)
    d.text((cx, int(by+bh+42*S)), "로그인 없이 시작", font=f(14), fill=SK_SOFT, anchor="mm")
    d.text((cx, H-int(80*S)), "Apple 계정으로 공유방 기능을 이용할 수 있어요.", font=f(11), fill=SK_SOFT, anchor="mm")
    img.save(os.path.join(OUT, "12_apple_signin.png"))

# ---------------- 13. Invite Code ----------------
def invite_code():
    img, d = sk_base()
    sk_navbar(d, "우리집", left="‹")
    y = 102*S
    d.text((24*S, y+10*S), "우리집", font=f(20,True), fill=SK_INK)
    draw_ink_line(d, y+40*S, W, seed=1301, thickness=1.8, alpha=0.30)
    y += 58*S

    sk_section_header(d, "멤버", y); y += 22*S
    draw_ink_line(d, y, W, seed=1302, thickness=1.8, alpha=0.30)
    y += 10*S
    for name, role, seed in [("나","소유자",1311),("민지","멤버",1312)]:
        draw_wobbly_square(d, int(20*S), int(y+6*S), int(28*S), seed)
        d.text((int(58*S),int(y+8*S)), name, font=f(14,True), fill=SK_INK)
        d.text((int(58*S),int(y+26*S)), role, font=f(11), fill=SK_SOFT)
        draw_ink_line(d, y+44*S, W, seed=seed+1, thickness=0.9, alpha=0.12)
        y += 48*S
    draw_ink_line(d, y, W, seed=1313, thickness=1.8, alpha=0.28)
    y += 20*S

    sk_section_header(d, "초대 코드", y); y += 22*S
    draw_ink_line(d, y, W, seed=1320, thickness=1.8, alpha=0.30)
    y += 16*S
    # 코드 크게
    d.text((32*S, y+6*S), "HJK", font=f(32,True), fill=SK_INK)
    d.text((int(W/2), y+8*S), "—", font=f(28), fill=SK_SOFT, anchor="mm")
    d.text((W/2+24*S, y+6*S), "9NP", font=f(32,True), fill=SK_INK)
    d.text((W-28*S, y+14*S), "⧉", font=f(22), fill=SK_INK, anchor="rm")
    y += 56*S
    d.text((24*S, y), "이 코드를 멤버에게 알려주세요.", font=f(12), fill=SK_SOFT)
    draw_ink_line(d, y+28*S, W, seed=1321, thickness=1.8, alpha=0.28)
    y += 44*S
    d.text((24*S, y+12*S), "↑ 초대 링크 공유", font=f(14), fill=SK_INK)
    draw_ink_line(d, y+44*S, W, seed=1322, thickness=1.8, alpha=0.28)
    img.save(os.path.join(OUT, "13_invite_code.png"))
    rows = [
        (1001, "available", "장보기",        "오늘",   None,      False),
        (2002, "locked",    "요리하기",       None,     None,      False),
        (3003, "available", "분리수거",       "내일",   None,      False),
        (4004, "available", "운동 30분",      "오늘",   "↺ 매일", False),
        (5005, "completed", "팀 미팅 참석",   "어제",   None,      True),
    ]
    y = 102 * S
    cb_size = 20 * S   # 사각형 체크박스 크기
    for (seed_b, status, title, date, badge, done) in rows:
        row_h = 56 * S

        # 행 구분 — 카드 배경 없이 줄선으로만 (참고 이미지 스타일)
        # 완료된 항목은 배경 살짝 채우기
        if done:
            d.rectangle([(0, y), (W, y+row_h)], fill=blend(SK_PAPER, SK_INK, 0.04))

        # 삐뚤한 사각형 체크박스
        cb_x = int(20*S)
        cb_y = int(y + (row_h - cb_size) // 2)
        draw_wobbly_square(d, cb_x, cb_y, cb_size, seed=seed_b,
                           done=done, locked=(status=="locked"))
        if done:
            draw_checkmark(d, cb_x, cb_y, cb_size, seed=seed_b)
        elif status == "locked":
            # X 표시
            m = int(cb_size * 0.25)
            d.line([(cb_x+m, cb_y+m), (cb_x+cb_size-m, cb_y+cb_size-m)], fill=SK_FADE, width=max(1,int(1.5*S)))
            d.line([(cb_x+cb_size-m, cb_y+m), (cb_x+m, cb_y+cb_size-m)], fill=SK_FADE, width=max(1,int(1.5*S)))

        # 제목
        tx = int(52*S)
        ty = int(y + row_h//2 - 8*S)
        title_col = SK_FADE if (done or status=="locked") else SK_INK
        d.text((tx, ty), title, font=f(15, True), fill=title_col)

        if done:
            # 취소선
            tw = len(title) * 8 * S
            rng_s = seeded_rng(seed_b + 55)
            sy = ty + int(10*S) + int((rng_s() * 2-1) * 1 * S)
            d.line([(tx, sy), (tx + tw, sy + int((rng_s()*2-1)*1.5*S))],
                   fill=SK_FADE, width=max(1, int(1.2*S)))

        # 날짜/뱃지
        by2 = int(y + row_h//2 + 10*S)
        bx = tx
        if date:
            d.text((bx, by2), date, font=f(10), fill=SK_SOFT)
            bx += int((len(date)*6+8)*S)
        if badge:
            d.text((bx, by2), badge, font=f(10), fill=SK_SOFT)

        # 행 하단 구분선
        draw_ink_line(d, y + row_h, W, seed=seed_b + 1, thickness=0.9, alpha=0.13)

        y += row_h

    # 섹션 헤더
    y += 6*S
    d.text((20*S, y), "완료됨  ·  최근 7일", font=f(11), fill=SK_SOFT)

    # 탭바
    d.rectangle([(0, H-80*S), (W, H)], fill=SK_PAPER)
    draw_ink_line(d, H-80*S, W, seed=888, thickness=2.0, alpha=0.35)
    items = [("☐","투두"), ("▦","캘린더"), ("○","공유방"), ("▤","템플릿"), ("⚙","설정")]
    for i, (ic, label) in enumerate(items):
        cx2 = int(W * (i+0.5) / 5)
        col = SK_INK if i==0 else SK_SOFT
        ic_font = f(20, True) if i == 0 else f(18)
        d.text((cx2, H-52*S), ic, font=ic_font, fill=col, anchor="mm")
        d.text((cx2, H-28*S), label, font=f(10, i==0), fill=col, anchor="mm")

    img.save(os.path.join(OUT, "14_sketch_todo.png"))

def apple_signin():
    img, d = base()
    # 중앙 로고
    cy = 280 * S
    d.text((W/2, cy), "✓", font=f(52, True), fill=BLUE, anchor="mm")
    d.text((W/2, cy + 70 * S), "todogether", font=f(28, True), fill=INK, anchor="mm")
    d.text((W/2, cy + 106 * S), "함께 만드는 할 일 목록", font=f(15), fill=SUB, anchor="mm")
    # Apple 로그인 버튼
    by = cy + 170 * S
    rounded(d, (32 * S, by, W - 32 * S, by + 50 * S), 12 * S, fill=(20, 20, 24))
    d.text((W/2, by + 26 * S), "🍎  Apple로 로그인", font=f(16, True), fill=(255, 255, 255), anchor="mm")
    # 건너뛰기
    d.text((W/2, by + 80 * S), "로그인 없이 시작", font=f(14), fill=SUB, anchor="mm")
    # 하단 안내
    d.text((W/2, H - 100 * S), "Apple 계정으로 로그인하면 공유방 기능과", font=f(11), fill=SUB, anchor="mm")
    d.text((W/2, H - 80 * S), "실시간 동기화를 이용할 수 있어요.", font=f(11), fill=SUB, anchor="mm")
    img.save(os.path.join(OUT, "12_apple_signin.png"))

def invite_code():
    img, d = base()
    navbar(d, "우리집", left="‹")
    y = 100 * S
    # 이름/색상
    rounded(d, (16 * S, y, W - 16 * S, y + 96 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "공유방 이름", font=f(12), fill=SUB)
    d.text((32 * S, y + 36 * S), "우리집", font=f(17, True), fill=INK)
    y += 116 * S
    # 멤버
    d.text((28 * S, y), "멤버", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 110 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "나  소유자", font=f(14), fill=INK)
    d.line([(32 * S, y + 50 * S), (W - 16 * S, y + 50 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 62 * S), "iCloud로 초대", font=f(14), fill=BLUE)
    d.line([(32 * S, y + 96 * S), (W - 16 * S, y + 96 * S)], fill=LINE, width=S)
    y += 130 * S
    # 초대 코드 섹션
    d.text((28 * S, y), "초대 코드", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 120 * S), 12 * S, fill=CARD)
    # 코드 표시 (3+3)
    d.text((40 * S, y + 20 * S), "HJK", font=f(28, True), fill=INK)
    d.text((108 * S, y + 20 * S), "-", font=f(24), fill=SUB)
    d.text((126 * S, y + 20 * S), "9NP", font=f(28, True), fill=INK)
    # 복사 아이콘
    d.text((W - 44 * S, y + 28 * S), "⧉", font=f(20), fill=BLUE, anchor="mm")
    d.text((32 * S, y + 70 * S), "이 코드를 멤버에게 알려주세요.", font=f(12), fill=SUB)
    d.text((32 * S, y + 88 * S), "코드로 공유방에 바로 참여할 수 있어요.", font=f(12), fill=SUB)
    d.line([(32 * S, y + 104 * S), (W - 16 * S, y + 104 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 108 * S), "↑ 초대 링크 공유", font=f(14), fill=BLUE)
    img.save(os.path.join(OUT, "13_invite_code.png"))

def add_todo_nlp():
    """AddTodoView — 자연어 날짜 파싱 힌트"""
    img, d = base()
    navbar(d, "새 할 일", left="취소", right_icons=["추가"])
    y = 100 * S
    # 입력 섹션 카드
    rounded(d, (16 * S, y, W - 16 * S, y + 100 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "할 일 (예: 내일 장보기)", font=f(14), fill=SUB)
    d.line([(32 * S, y + 44 * S), (W - 32 * S, y + 44 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 52 * S), "다음주 월요일 팀 미팅", font=f(16), fill=INK)
    # 파싱 힌트
    d.text((32 * S, y + 76 * S), "✦ 날짜 인식: 6월 30일 월요일", font=f(12), fill=BLUE)
    y += 116 * S
    # 날짜 지정 토글 (자동 ON)
    rounded(d, (16 * S, y, W - 16 * S, y + 50 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "날짜 지정", font=f(14), fill=INK)
    rounded(d, (W - 76 * S, y + 12 * S, W - 32 * S, y + 36 * S), 12 * S, fill=GREEN)
    d.ellipse((W - 54 * S, y + 14 * S, W - 34 * S, y + 34 * S), fill=(255, 255, 255))
    y += 54 * S
    # DatePicker
    rounded(d, (16 * S, y, W - 16 * S, y + 50 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "날짜", font=f(14), fill=INK)
    d.text((W - 32 * S, y + 16 * S), "2026년 6월 30일", font=f(14), fill=BLUE, anchor="rm")
    img.save(os.path.join(OUT, "11_add_todo_nlp.png"))

def settings():
    img, d = base()
    navbar(d, "설정")
    y = 100 * S
    # 보안 섹션
    d.text((28 * S, y), "보안", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 96 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "Face ID / Touch ID 잠금", font=f(14), fill=INK)
    rounded(d, (W - 76 * S, y + 12 * S, W - 32 * S, y + 36 * S), 12 * S, fill=GREEN)
    d.ellipse((W - 54 * S, y + 14 * S, W - 34 * S, y + 34 * S), fill=(255, 255, 255))
    d.text((32 * S, y + 52 * S), "앱 실행 및 백그라운드 복귀 시 생체 인증이 필요합니다.", font=f(11), fill=SUB)
    y += 120 * S
    # 알림 섹션
    d.text((28 * S, y), "알림", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 48 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "알림 설정", font=f(14), fill=INK)
    d.text((W - 32 * S, y + 16 * S), "›", font=f(18), fill=SUB, anchor="rm")
    y += 72 * S
    # 앱 정보 섹션
    d.text((28 * S, y), "앱 정보", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 48 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "버전", font=f(14), fill=INK)
    d.text((W - 32 * S, y + 16 * S), "1.0.0", font=f(14), fill=SUB, anchor="rm")
    tabbar(d, 4)
    img.save(os.path.join(OUT, "09_settings.png"))

def todo_list_claiming():
    """투두 리스트 — 미배정 뱃지 + 클레이밍 스와이프 시각화"""
    img, d = base()
    navbar(d, "우리집", left="‹", right_icons=["+"])
    y = 100 * S
    rows = [
        ("circle", "설거지 하기", "오늘", None, PURPLE, False, False),
        ("circle", "쓰레기 버리기", "내일", None, ORANGE, True, False),   # 미배정
        ("lock", "요리하기", None, None, PURPLE, False, False),
    ]
    card_h = 68 * S
    rounded(d, (16 * S, y, W - 16 * S, y + card_h * len(rows)), 14 * S, fill=CARD)
    for i, (icon, title, date, badge, dot, unassigned, done) in enumerate(rows):
        ry = y + i * card_h
        cx = 40 * S
        if icon == "lock":
            d.ellipse((cx - 11 * S, ry + card_h/2 - 11 * S, cx + 11 * S, ry + card_h/2 + 11 * S), outline=SUB, width=2 * S)
        else:
            d.ellipse((cx - 11 * S, ry + card_h/2 - 11 * S, cx + 11 * S, ry + card_h/2 + 11 * S), outline=SUB, width=2 * S)
        d.ellipse((62 * S, ry + card_h/2 - 5 * S, 72 * S, ry + card_h/2 + 5 * S), fill=dot)
        d.text((84 * S, ry + 14 * S), title, font=f(16), fill=INK if icon != "lock" else SUB)
        sub_y = ry + 36 * S
        if date:
            d.text((84 * S, sub_y), date, font=f(11), fill=SUB)
        if unassigned:
            # 미배정 뱃지
            bx = 84 * S + (44 * S if date else 0)
            badge_w = 48 * S
            rounded(d, (bx, sub_y - 2 * S, bx + badge_w, sub_y + 18 * S), 10 * S, fill=(10, 122, 255, 40))
            d.text((bx + badge_w // 2, sub_y + 7 * S), "미배정", font=f(10), fill=BLUE, anchor="mm")
        if i < len(rows) - 1:
            d.line([(32 * S, ry + card_h), (W - 16 * S, ry + card_h)], fill=LINE, width=S)
    # 스와이프 힌트 (두번째 행)
    sy = y + card_h + 4 * S
    rounded(d, (W - 140 * S, sy, W - 16 * S, sy + card_h - 8 * S), 12 * S, fill=BLUE)
    d.text((W - 78 * S, sy + card_h // 2 - 8 * S), "내가", font=f(12, True), fill=(255,255,255), anchor="mm")
    d.text((W - 78 * S, sy + card_h // 2 + 10 * S), "할게", font=f(12, True), fill=(255,255,255), anchor="mm")
    tabbar(d, 0)
    img.save(os.path.join(OUT, "10_todo_claiming.png"))

if __name__ == "__main__":
    todo_list(); todo_detail(); calendar(); widget()
    onboarding(); space_detail(); reaction(); notif_settings()
    settings(); todo_list_claiming(); add_todo_nlp()
    apple_signin(); invite_code()
    print("emoji_color:", _emoji_ok)
    print("rendered:", sorted(os.listdir(OUT)))
