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

KR = "/usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf"
KRB = "/usr/share/fonts/truetype/nanum/NanumBarunGothicBold.ttf"
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

# 손글씨 메모장 테마 색상
SK_PAPER  = (254, 250, 224)   # #FEFAE0 크림
SK_CARD   = (255, 253, 245)   # #FFFDF5
SK_INK    = (45,  42,  34)    # #2D2A22 따뜻한 다크
SK_SOFT   = (140, 123, 107)   # #8C7B6B 연한 갈색
SK_RULE   = (196, 184, 160)   # #C4B8A0 줄선
SK_ACCENT = (224, 122,  95)   # #E07A5F 테라코타
SK_SAGE   = (129, 178, 154)   # #81B29A 세이지
SK_SAND   = (196, 168, 130)   # #C4A882

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

# ---------------- 1. Todo List ----------------
def todo_list():
    img, d = base()
    navbar(d, "투두", left="≣", right_icons=["+"])
    y = 100 * S
    # 활성 카드
    rows = [
        ("circle", "장보기", "오늘", None, PURPLE, False),
        ("lock", "요리하기", None, "매주 월·수·금", PURPLE, False),
        ("circle", "분리수거", "내일", None, ORANGE, False),
    ]
    card_h = 64 * S
    rounded(d, (16 * S, y, W - 16 * S, y + card_h * len(rows)), 14 * S, fill=CARD)
    for i, (icon, title, date, badge, dot, done) in enumerate(rows):
        ry = y + i * card_h
        cx = 40 * S
        if icon == "lock":
            d.ellipse((cx - 11 * S, ry + card_h/2 - 11 * S, cx + 11 * S, ry + card_h/2 + 11 * S), outline=SUB, width=2 * S)
            d.text((cx, ry + card_h/2), "🔒", font=f(11), fill=SUB, anchor="mm")
        else:
            d.ellipse((cx - 11 * S, ry + card_h/2 - 11 * S, cx + 11 * S, ry + card_h/2 + 11 * S), outline=SUB, width=2 * S)
        # space dot
        d.ellipse((62 * S, ry + card_h/2 - 5 * S, 72 * S, ry + card_h/2 + 5 * S), fill=dot)
        tcol = SUB if icon == "lock" else INK
        d.text((84 * S, ry + 18 * S), title, font=f(16), fill=tcol)
        meta_x = 84 * S
        if date:
            d.text((meta_x, ry + 40 * S), date, font=f(12), fill=SUB)
            meta_x += 60 * S
        if badge:
            d.text((meta_x, ry + 40 * S), "↻ " + badge, font=f(12), fill=SUB)
        if i < len(rows) - 1:
            d.line([(84 * S, ry + card_h), (W - 16 * S, ry + card_h)], fill=LINE, width=S)
    y += card_h * len(rows) + 24 * S
    # 완료 섹션
    d.text((28 * S, y), "완료됨 · 최근 7일", font=f(13, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 76 * S), 14 * S, fill=CARD)
    cx = 40 * S
    d.ellipse((cx - 11 * S, y + 22 * S, cx + 11 * S, y + 44 * S), fill=GREEN)
    d.line([(cx - 5 * S, y + 33 * S), (cx - 1 * S, y + 38 * S), (cx + 6 * S, y + 27 * S)], fill=(255, 255, 255), width=2 * S)
    d.ellipse((62 * S, y + 28 * S, 72 * S, y + 38 * S), fill=PURPLE)
    d.text((84 * S, y + 16 * S), "설거지", font=f(16), fill=SUB)
    # 취소선
    tw = d.textlength("설거지", font=f(16))
    d.line([(84 * S, y + 25 * S), (84 * S + tw, y + 25 * S)], fill=SUB, width=S)
    # 반응 칩
    chipx = 84 * S
    for ch, cnt in [("👍", "2"), ("❤️", "1"), ("🎉", "1")]:
        cw = 44 * S
        rounded(d, (chipx, y + 46 * S, chipx + cw, y + 66 * S), 10 * S, fill=(238, 240, 245))
        if not paste_emoji(img, ch, (chipx + 6 * S, y + 49 * S), 15 * S):
            d.text((chipx + 6 * S, y + 49 * S), "•", font=f(13), fill=INK)
        d.text((chipx + 26 * S, y + 49 * S), cnt, font=f(11, True), fill=SUB)
        chipx += cw + 6 * S
    tabbar(d, 0)
    img.save(os.path.join(OUT, "01_todo_list.png"))

# ---------------- 2. Todo Detail ----------------
def todo_detail():
    img, d = base()
    navbar(d, "할 일", left="‹ 투두")
    y = 100 * S
    def section(title, rows_h):
        nonlocal y
        d.text((28 * S, y), title, font=f(12, True), fill=SUB)
        y += 22 * S
        rounded(d, (16 * S, y, W - 16 * S, y + rows_h), 12 * S, fill=CARD)
    section("", 92 * S)
    d.text((32 * S, y + 16 * S), "요리하기", font=f(17, True), fill=INK)
    d.line([(32 * S, y + 46 * S), (W - 32 * S, y + 46 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 58 * S), "재료 손질부터 시작", font=f(14), fill=SUB)
    y += 92 * S + 20 * S
    section("마감", 96 * S)
    d.text((32 * S, y + 16 * S), "날짜 지정", font=f(15), fill=INK)
    d.text((W - 36 * S, y + 14 * S), "ON", font=f(12, True), fill=(255, 255, 255), anchor="rm")
    rounded(d, (W - 78 * S, y + 8 * S, W - 32 * S, y + 32 * S), 12 * S, fill=GREEN)
    d.ellipse((W - 54 * S, y + 10 * S, W - 34 * S, y + 30 * S), fill=(255, 255, 255))
    d.line([(32 * S, y + 48 * S), (W - 32 * S, y + 48 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 60 * S), "마감일", font=f(15), fill=INK)
    d.text((W - 32 * S, y + 60 * S), "6월 25일", font=f(15), fill=BLUE, anchor="rm")
    y += 96 * S + 20 * S
    section("반복", 48 * S)
    d.text((32 * S, y + 15 * S), "↻ 반복", font=f(15), fill=INK)
    d.text((W - 32 * S, y + 15 * S), "매주 월·수·금", font=f(15), fill=SUB, anchor="rm")
    y += 48 * S + 20 * S
    # 연계
    d.text((28 * S, y), "이 일을 하기 전에", font=f(12, True), fill=SUB)
    y += 22 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 92 * S), 12 * S, fill=CARD)
    d.ellipse((34 * S, y + 16 * S, 50 * S, y + 32 * S), fill=GREEN)
    d.line([(38 * S, y + 24 * S), (41 * S, y + 28 * S), (47 * S, y + 19 * S)], fill=(255, 255, 255), width=2 * S)
    d.text((62 * S, y + 15 * S), "장보기", font=f(15), fill=INK)
    d.line([(32 * S, y + 46 * S), (W - 32 * S, y + 46 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 58 * S), "🔗 선행 조건 추가", font=f(15), fill=BLUE)
    y += 92 * S + 10 * S
    d.text((28 * S, y), "선행 조건이 완료되면 자동으로 활성화돼요", font=f(11), fill=SUB)
    img.save(os.path.join(OUT, "02_todo_detail.png"))

# ---------------- 3. Calendar ----------------
def calendar():
    img, d = base()
    navbar(d, "캘린더", right_icons=["▦"])
    y = 100 * S
    # 주간 스트립
    days = ["일", "월", "화", "수", "목", "금", "토"]
    nums = [22, 23, 24, 25, 26, 27, 28]
    dots = [[], [PURPLE], [ORANGE, PURPLE], [PURPLE], [], [BLUE], []]
    cellw = (W - 32 * S) / 7
    for i in range(7):
        cx = 16 * S + cellw * (i + 0.5)
        d.text((cx, y), days[i], font=f(11), fill=SUB, anchor="mm")
        sel = (i == 2)
        if sel:
            d.ellipse((cx - 16 * S, y + 16 * S, cx + 16 * S, y + 48 * S), fill=BLUE)
        d.text((cx, y + 32 * S), str(nums[i]), font=f(15, True if i == 2 else False),
               fill=(255, 255, 255) if sel else INK, anchor="mm")
        dx = cx - (len(dots[i]) - 1) * 4 * S
        for c in dots[i]:
            d.ellipse((dx - 2.5 * S, y + 56 * S, dx + 2.5 * S, y + 61 * S), fill=c)
            dx += 8 * S
    y += 80 * S
    d.line([(0, y), (W, y)], fill=LINE, width=S)
    y += 16 * S
    # 피드 섹션
    def feed_section(title, color, items):
        nonlocal y
        d.text((28 * S, y), title, font=f(13, True), fill=color)
        y += 26 * S
        rounded(d, (16 * S, y, W - 16 * S, y + 56 * S * len(items)), 12 * S, fill=CARD)
        for j, (t, dot, tint) in enumerate(items):
            ry = y + j * 56 * S
            d.ellipse((36 * S, ry + 18 * S, 56 * S, ry + 38 * S), outline=SUB, width=2 * S)
            d.ellipse((66 * S, ry + 23 * S, 76 * S, ry + 33 * S), fill=dot)
            d.text((88 * S, ry + 18 * S), t, font=f(15), fill=INK)
            if tint:
                rounded(d, (W - 70 * S, ry + 16 * S, W - 26 * S, ry + 38 * S), 8 * S, fill=(255, 235, 235))
                d.text((W - 48 * S, ry + 20 * S), "지남", font=f(11, True), fill=RED, anchor="mm")
            if j < len(items) - 1:
                d.line([(88 * S, ry + 56 * S), (W - 16 * S, ry + 56 * S)], fill=LINE, width=S)
        y += 56 * S * len(items) + 18 * S
    feed_section("마감 지남", RED, [("월세 이체", BLUE, True)])
    feed_section("오늘", INK, [("장보기", PURPLE, False), ("운동하기", ORANGE, False)])
    feed_section("내일", INK, [("분리수거", PURPLE, False)])
    tabbar(d, 1)
    img.save(os.path.join(OUT, "03_calendar.png"))

# ---------------- 4. Widget ----------------
def widget():
    img = Image.new("RGB", (W, H), (60, 70, 95))
    d = ImageDraw.Draw(img)
    # 그라데이션 느낌 배경
    for i in range(H):
        t = i / H
        col = (int(60 + 40 * t), int(70 + 30 * t), int(95 + 20 * t))
        d.line([(0, i), (W, i)], fill=col)
    d.text((20 * S, 14 * S), "9:41", font=f(14, True), fill=(255, 255, 255))
    # 위젯 카드 (medium)
    mx, my = 24 * S, 120 * S
    mw, mh = W - 48 * S, 170 * S
    rounded(d, (mx, my, mx + mw, my + mh), 24 * S, fill=(255, 255, 255))
    d.text((mx + 22 * S, my + 18 * S), "오늘 할 일", font=f(13, True), fill=SUB)
    rows = [("장보기", False), ("요리하기", False), ("운동하기", True), ("분리수거", False)]
    ry = my + 46 * S
    for t, done in rows:
        cx = mx + 32 * S
        if done:
            d.ellipse((cx - 10 * S, ry, cx + 10 * S, ry + 20 * S), fill=GREEN)
            d.line([(cx - 4 * S, ry + 10 * S), (cx - 1 * S, ry + 14 * S), (cx + 5 * S, ry + 5 * S)], fill=(255, 255, 255), width=2 * S)
        else:
            d.ellipse((cx - 10 * S, ry, cx + 10 * S, ry + 20 * S), outline=SUB, width=2 * S)
        col = SUB if done else INK
        d.text((cx + 22 * S, ry), t, font=f(15), fill=col)
        if done:
            tw = d.textlength(t, font=f(15))
            d.line([(cx + 22 * S, ry + 10 * S), (cx + 22 * S + tw, ry + 10 * S)], fill=SUB, width=S)
        ry += 30 * S
    d.text((W/2, my + mh + 30 * S), "todogether 위젯 · 탭하면 완료", font=f(12), fill=(230, 230, 240), anchor="mm")
    img.save(os.path.join(OUT, "04_widget.png"))

# ---------------- 5. Onboarding ----------------
def onboarding():
    img, d = base()
    cx = W / 2
    # 아이콘 원
    d.ellipse((cx - 70 * S, 250 * S, cx + 70 * S, 390 * S), fill=(237, 236, 252))
    d.text((cx, 320 * S), "👥", font=f(48), fill=PURPLE, anchor="mm")
    paste_emoji(img, "👥", (cx - 30 * S, 290 * S), 60 * S)
    d.text((cx, 430 * S), "공유방으로 같이", font=f(26, True), fill=INK, anchor="mm")
    d.text((cx, 478 * S), "가족·친구와 공유방을 만들어 할 일을 나눠요.", font=f(15), fill=SUB, anchor="mm")
    d.text((cx, 504 * S), "누가 끝냈는지 바로 알 수 있어요.", font=f(15), fill=SUB, anchor="mm")
    # 페이지 닷
    for i in range(3):
        c = PURPLE if i == 1 else (210, 210, 218)
        dx = cx - 16 * S + i * 16 * S
        d.ellipse((dx - 4 * S, 560 * S, dx + 4 * S, 568 * S), fill=c)
    # 버튼
    rounded(d, (40 * S, 700 * S, W - 40 * S, 750 * S), 14 * S, fill=BLUE)
    d.text((cx, 725 * S), "다음", font=f(17, True), fill=(255, 255, 255), anchor="mm")
    d.text((cx, 775 * S), "건너뛰기", font=f(14), fill=SUB, anchor="mm")
    img.save(os.path.join(OUT, "05_onboarding.png"))

# ---------------- 6. Space Detail ----------------
def space_detail():
    img, d = base()
    navbar(d, "우리집", left="‹ 공유방")
    y = 100 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 110 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "공유방 이름", font=f(12), fill=SUB)
    d.text((32 * S, y + 36 * S), "우리집", font=f(17, True), fill=INK)
    d.line([(32 * S, y + 70 * S), (W - 32 * S, y + 70 * S)], fill=LINE, width=S)
    palette = [(94, 92, 230), (255, 107, 107), (78, 205, 196), (69, 183, 209), (150, 206, 180), (255, 234, 167)]
    px = 36 * S
    for i, c in enumerate(palette):
        d.ellipse((px, y + 82 * S, px + 22 * S, y + 104 * S), fill=c)
        if i == 1:
            d.line([(px + 6 * S, y + 93 * S), (px + 10 * S, y + 98 * S), (px + 17 * S, y + 87 * S)], fill=(255, 255, 255), width=2 * S)
        px += 32 * S
    y += 130 * S
    d.text((28 * S, y), "멤버", font=f(12, True), fill=SUB)
    y += 24 * S
    members = [("나", "소유자", False), ("민지", "멤버", False), ("지호", "멤버", True)]
    rounded(d, (16 * S, y, W - 16 * S, y + 56 * S * len(members) + 48 * S), 12 * S, fill=CARD)
    for i, (name, role, pending) in enumerate(members):
        ry = y + i * 56 * S
        d.ellipse((34 * S, ry + 14 * S, 62 * S, ry + 42 * S), fill=(210, 212, 220))
        d.text((74 * S, ry + 14 * S), name, font=f(15), fill=INK)
        d.text((74 * S, ry + 36 * S), role, font=f(11), fill=SUB)
        if pending:
            rounded(d, (W - 90 * S, ry + 16 * S, W - 28 * S, ry + 40 * S), 10 * S, fill=(255, 247, 214))
            d.text((W - 59 * S, ry + 20 * S), "대기 중", font=f(11), fill=ORANGE, anchor="mm")
        d.line([(34 * S, ry + 56 * S), (W - 16 * S, ry + 56 * S)], fill=LINE, width=S)
    iy = y + 56 * S * len(members)
    d.text((34 * S, iy + 14 * S), "＋ 사람 초대하기", font=f(15), fill=BLUE)
    y += 56 * S * len(members) + 48 * S + 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 48 * S), 12 * S, fill=CARD)
    d.text((34 * S, y + 15 * S), "🗑 공유방 삭제", font=f(15), fill=RED)
    img.save(os.path.join(OUT, "06_space_detail.png"))

# ---------------- 7. Reaction picker ----------------
def reaction():
    img, d = base()
    navbar(d, "투두", left="≣", right_icons=["+"])
    y = 160 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 76 * S), 14 * S, fill=CARD)
    cx = 40 * S
    d.ellipse((cx - 11 * S, y + 22 * S, cx + 11 * S, y + 44 * S), fill=GREEN)
    d.line([(cx - 5 * S, y + 33 * S), (cx - 1 * S, y + 38 * S), (cx + 6 * S, y + 27 * S)], fill=(255, 255, 255), width=2 * S)
    d.text((84 * S, y + 26 * S), "설거지", font=f(16), fill=SUB)
    d.text((W - 36 * S, y + 26 * S), "민지", font=f(13), fill=SUB, anchor="rm")
    # 반응 피커 버블
    by = y + 96 * S
    bw = 300 * S
    bx = (W - bw) / 2
    rounded(d, (bx, by, bx + bw, by + 56 * S), 28 * S, fill=(255, 255, 255), outline=LINE, width=S)
    emojis = ["👍", "❤️", "🎉", "💪", "😂", "🙏"]
    ex = bx + 18 * S
    for ch in emojis:
        if not paste_emoji(img, ch, (ex, by + 14 * S), 30 * S):
            d.text((ex, by + 14 * S), "•", font=f(22), fill=INK)
        ex += 46 * S
    d.text((W/2, by + 88 * S), "완료된 공유 할 일을 길게 눌러 반응", font=f(12), fill=SUB, anchor="mm")
    tabbar(d, 0)
    img.save(os.path.join(OUT, "07_reaction.png"))

# ---------------- 8. Notification settings ----------------
def notif_settings():
    img, d = base()
    navbar(d, "알림", left="‹ 설정")
    y = 100 * S
    d.text((28 * S, y), "알림 종류", font=f(12, True), fill=SUB)
    y += 24 * S
    toggles = [("마감 알림", True), ("연계 해제 (이제 할 수 있어요)", True),
               ("공유방 완료 알림", True), ("콕 찌르기", True), ("반응 알림", False)]
    rounded(d, (16 * S, y, W - 16 * S, y + 50 * S * len(toggles)), 12 * S, fill=CARD)
    for i, (label, on) in enumerate(toggles):
        ry = y + i * 50 * S
        d.text((32 * S, ry + 16 * S), label, font=f(14), fill=INK)
        tc = GREEN if on else (200, 202, 210)
        rounded(d, (W - 76 * S, ry + 12 * S, W - 32 * S, ry + 36 * S), 12 * S, fill=tc)
        knob = (W - 54 * S) if on else (W - 74 * S)
        d.ellipse((knob, ry + 14 * S, knob + 20 * S, ry + 34 * S), fill=(255, 255, 255))
        if i < len(toggles) - 1:
            d.line([(32 * S, ry + 50 * S), (W - 16 * S, ry + 50 * S)], fill=LINE, width=S)
    y += 50 * S * len(toggles) + 24 * S
    d.text((28 * S, y), "방해 금지", font=f(12, True), fill=SUB)
    y += 24 * S
    rounded(d, (16 * S, y, W - 16 * S, y + 150 * S), 12 * S, fill=CARD)
    d.text((32 * S, y + 16 * S), "방해 금지 시간", font=f(14), fill=INK)
    rounded(d, (W - 76 * S, y + 12 * S, W - 32 * S, y + 36 * S), 12 * S, fill=GREEN)
    d.ellipse((W - 54 * S, y + 14 * S, W - 34 * S, y + 34 * S), fill=(255, 255, 255))
    d.line([(32 * S, y + 50 * S), (W - 32 * S, y + 50 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 62 * S), "시작", font=f(14), fill=INK)
    d.text((W - 32 * S, y + 62 * S), "22시", font=f(14), fill=SUB, anchor="rm")
    d.line([(32 * S, y + 96 * S), (W - 32 * S, y + 96 * S)], fill=LINE, width=S)
    d.text((32 * S, y + 108 * S), "종료", font=f(14), fill=INK)
    d.text((W - 32 * S, y + 108 * S), "8시", font=f(14), fill=SUB, anchor="rm")
    y += 150 * S + 10 * S
    d.text((28 * S, y), "자정을 넘는 구간(22시~8시)도 설정할 수 있어요", font=f(11), fill=SUB)
    img.save(os.path.join(OUT, "08_notif_settings.png"))

def sketch_todo_list():
    """손글씨 메모장 감성 투두 리스트"""
    img = Image.new("RGB", (W, H), SK_PAPER)
    d = ImageDraw.Draw(img)
    # 줄노트 배경
    for i in range(60):
        y = (50 + i * 36) * S
        d.line([(0, y), (W, y)], fill=SK_RULE, width=1)
    # 상태바
    d.text((20*S, 14*S), "9:41", font=f(14,True), fill=SK_INK)
    d.text((W-70*S, 14*S), "▮▮▮ ▮", font=f(12), fill=SK_INK)
    # 네비바
    d.line([(0, 90*S), (W, 90*S)], fill=SK_RULE, width=1)
    d.text((W/2, 62*S), "투두", font=f(20,True), fill=SK_INK, anchor="mm")
    d.text((20*S, 62*S), "≡", font=f(22), fill=SK_SOFT, anchor="lm")
    d.text((W-24*S, 62*S), "✏", font=f(20), fill=SK_ACCENT, anchor="rm")

    # (status, title, date_str, badge_str, dot_color, done)
    rows = [
        ("available", "장보기",       "오늘",   None,      (94,92,230),   False),
        ("locked",    "요리하기",      None,     None,      (94,92,230),   False),
        ("available", "분리수거",      "내일",   None,      (224,122,95),  False),
        ("available", "운동 30분",     "오늘",   "↺ 매일", (129,178,154), False),
        ("completed", "팀 미팅 참석",  "어제",   None,      (94,92,230),   True),
    ]
    y = 108 * S
    for (status, title, date, badge, dot, done) in rows:
        row_h = 58 * S
        # 카드 배경
        rounded(d, (12*S, y+2*S, W-12*S, y+row_h-4*S), 10*S, fill=SK_CARD)
        rounded(d, (12*S, y+2*S, W-12*S, y+row_h-4*S), 10*S,
                outline=SK_RULE, width=1)

        # 손글씨 체크박스
        cx, cy2 = int(36*S), int(y + row_h//2)
        r = int(11*S)
        # 약간 삐뚤한 원
        pts = []
        import math
        for i in range(8):
            a = i / 8 * 2 * math.pi
            wobble_r = r + [-1,-1,1,1,0,-1,1,0][i]
            pts.append((cx + wobble_r*math.cos(a), cy2 + wobble_r*math.sin(a)))
        for i in range(len(pts)):
            p1, p2 = pts[i], pts[(i+1)%len(pts)]
            col = SK_SAGE if done else (SK_SAND if status=="locked" else SK_SOFT)
            d.line([p1, p2], fill=col, width=int(1.8*S))
        if done:
            # 체크 표시
            d.line([(cx-5*S, cy2+1*S), (cx-1*S, cy2+5*S)], fill=SK_SAGE, width=int(2.2*S))
            d.line([(cx-1*S, cy2+5*S), (cx+6*S, cy2-5*S)], fill=SK_SAGE, width=int(2.2*S))
        elif status == "locked":
            d.text((cx, cy2), "🔒", font=f(9), fill=SK_SAND, anchor="mm")

        # 공유방 색상 점
        d.ellipse((54*S, cy2-4*S, 62*S, cy2+4*S), fill=dot)

        # 제목
        tx = 70 * S
        title_col = SK_SOFT if (done or status=="locked") else SK_INK
        d.text((tx, y+14*S), title, font=f(15,True), fill=title_col)
        if done:
            d.line([(tx, y+22*S), (tx + len(title)*8*S, y+22*S)], fill=SK_SOFT, width=1)

        # 뱃지
        bx = tx
        if date:
            date_col = SK_ACCENT if (not done and date=="오늘") else SK_SOFT
            d.text((bx, y+38*S), date, font=f(10), fill=date_col)
            bx += (len(date)*7+4)*S
        if badge:
            d.text((bx, y+38*S), badge, font=f(10), fill=SK_SOFT)

        y += row_h

    # 완료됨 섹션 헤더
    y += 8*S
    d.text((24*S, y), "완료됨 · 최근 7일", font=f(11), fill=SK_SOFT)
    y += 24*S

    # 탭바 (크림 배경)
    d.rectangle([(0, H-80*S), (W, H)], fill=SK_PAPER)
    d.line([(0, H-80*S), (W, H-80*S)], fill=SK_RULE, width=1)
    items = [("□","투두"), ("▦","캘린더"), ("◎","공유방"), ("▤","템플릿"), ("⚙","설정")]
    for i, (ic, label) in enumerate(items):
        cx2 = W * (i+0.5) / 5
        col = SK_ACCENT if i==0 else SK_SOFT
        d.text((cx2, H-52*S), ic, font=f(18), fill=col, anchor="mm")
        d.text((cx2, H-28*S), label, font=f(10), fill=col, anchor="mm")

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
    apple_signin(); invite_code(); sketch_todo_list()
    print("emoji_color:", _emoji_ok)
    print("rendered:", sorted(os.listdir(OUT)))
