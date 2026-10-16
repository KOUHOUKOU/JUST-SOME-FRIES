"""Round 20: writes tr_zz_r20b.py (the big brother's new talks, the new ending lines) from the (english, simplified chinese, japanese) rows below.
The traditional Chinese column is made from the simplified one with a character table learned from the existing hand-made tables (zh_CN vs zh_TW of every row of tr_*.py);
a few ambiguous characters are handled by hand. Run:  python tools/i18n/gen_r20b.py   (then python tools/i18n/build.py)
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))

ROWS = [
("You've got the squint now. ...You're starting to look like me.", "你也会眯眼了。……你越来越像我了。", "お前も目を細めるようになったな。……だんだんおれに似てきた。"),
("Not sure that's a compliment. To either of us.", "不知道这算不算夸奖。对你，对我，都一样。", "ほめ言葉かどうかは分からん。お前にとっても、おれにとってもな。"),
("I had them all, once. I could name every one in my sleep.", "我也曾经全都有过。闭着眼睛都叫得出每一种的名字。", "おれも昔は全部持ってた。寝ぼけてても、ぜんぶ名前が言えた。"),
("Years of chasing magic fries. The fast ones. The shiny ones. The ones that sing.", "那些年一直在追魔法薯条。快的，亮的，会唱歌的。", "何年も魔法のポテトを追いかけた。速いやつ。光るやつ。歌うやつ。"),
("And somewhere in all that, I lost track of the first one. Where it was. What it tasted like.", "追着追着，我忘了第一根薯条在哪儿，是什么味道。", "追いかけてるうちに、最初の1本を見失った。どこにあったのか。どんな味だったのか。"),
("...still hungry?", "还饿吗？", "まだ、はらぺこ？"),
("Always. That's the trick of it.", "一直饿。这就是它的把戏。", "いつもだ。そこがミソなんだ。"),
("It never was the kind you can see on a plate.", "它从来就不是盘子里看得见的那种东西。", "皿の上に見えるようなものじゃなかった、最初から。"),
("That hat. ...Where'd you find it?", "这帽子。……你在哪儿找到的？", "その帽子。……どこで拾った？"),
("No. Don't tell me. A hat should keep its own story.", "不，别告诉我。帽子的故事，该由帽子自己留着。", "いや、言うな。帽子の話は、帽子のものだ。"),
("Wear it low. The sun is rude up here.", "压低点戴。这上面的太阳没礼貌。", "深めにかぶれ。ここの太陽は遠慮がない。"),
("You smell like a cafe, a bar and a freezer.", "你身上一股咖啡馆、酒吧加冷柜的味儿。", "カフェとバーと冷凍庫のにおいがする。"),
("...Respect.", "……佩服。", "……敬意を表する。"),
("I never trusted a gull who couldn't hold a cocktail and a grudge at the same time.", "我从不信任那种没法一边端着鸡尾酒、一边揣着怨气的海鸥。", "カクテルと恨みを同時に持てないカモメは、信用しない主義だ。"),
("I smelled the sea on you.", "我在你身上闻到了海的味道。", "お前から海のにおいがした。"),
("So it gave you something. It never gave me anything.", "这么说，它给了你点东西。它从没给过我什么。", "そうか、海はお前に何かくれたのか。おれには何もくれなかったがな。"),
("...I never asked politely.", "……我从没礼貌地问过。", "……おれは、ていねいに頼んだことがなかった。"),
("Say thank you on your way out, kid. The water remembers manners.", "走的时候记得说声谢谢，小家伙。水是记礼数的。", "帰りにありがとうを言っとけ、おチビ。水は礼儀を覚えてる。"),
("That streak across the sky the other day. Every colour. Very loud.", "前两天划过天空的那道光。什么颜色都有。吵得很。", "こないだ空を走ってった筋。ありとあらゆる色。やかましいやつだ。"),
("I used to leave one of those.", "我以前也留下过一道。", "おれも昔は、ああいうのを残してた。"),
("People on the pier thought it was a plane.", "码头上的人还以为是架飞机。", "桟橋の連中は飛行機だと思ってた。"),
("...It was me. Mostly.", "……是我。差不多吧。", "……おれだった。たいてい。"),
("I saw a gull land next to you. Just to say hello.", "我看见有只海鸥落在你旁边，就为了打声招呼。", "お前の隣にカモメが降りてきたのを見た。あいさつしに来ただけで。"),
("Do they do that now?", "现在流行这样了？", "今はそういうことするのか？"),
("In my day we ignored each other. Out of respect. And pride.", "我那会儿，大家互相不理睬。出于尊重，还有骄傲。", "おれの頃は、お互い無視し合った。敬意と、プライドからな。"),
("And fear of the hat.", "也怕那顶帽子。", "あと、帽子がこわかったってのもある。"),
("You wore a cloud. ...How was it?", "你戴过一朵云。……感觉怎么样？", "雲をかぶったそうだな。……どうだった？"),
("...soft.", "软软的。", "ふわふわ。"),
("Soft. Yes. That's what I'd forgotten about the sky.", "软软的。对。我忘了天空是这样的。", "ふわふわ、か。そうだった。空のそういうところを忘れてた。"),
("Everybody looks up and sees height. Nobody mentions the cushions.", "人人抬头只看见高度，没人提起那些软垫子。", "みんな空を見上げて高さばかり見る。クッションの話は誰もしない。"),
("A rain cloud. Your own private weather.", "一朵雨云。你专属的天气。", "雨雲か。自分専用の天気だな。"),
("I had one of those, years ago. It only ever rained on my hat.", "我多年前也有过一朵。它只往我的帽子上下雨。", "何年か前、おれにもあった。降るのは、いつもおれの帽子の上だけだった。"),
("...That's why the hat is waterproof. Mostly.", "……所以这顶帽子防水。大体上。", "……だから、この帽子は防水なんだ。だいたいな。"),
("A falling star. In your beak, no less.", "一颗流星。居然叼在你嘴里。", "流れ星か。しかも、お前のくちばしの中に。"),
("Did you wish?", "许愿了吗？", "願いごとはしたか？"),
("...beak was full.", "嘴里塞满了。", "くちばしがいっぱいだった。"),
("Ha. Good. Wishes are for gulls with nothing in their beaks.", "哈。好。许愿是留给嘴里空着的海鸥的。", "はは。いい。願いごとってのは、くちばしが空っぽのカモメがするもんだ。"),
("I wished once. For a hat. ...Look how that went.", "我许过一次愿。要一顶帽子。……看看后来怎么样了。", "一度だけ願ったことがある。帽子をくれ、とな。……ご覧のとおりだ。"),
("I flew at it all night.", "我冲着它飞了一整夜。", "一晩じゅう、あれに向かって飛んだ。"),
("By morning I was at the far end of the island and it was still up there. Calm as a plate.", "天亮时我到了岛的另一头，它还在上面，平静得像个盘子。", "朝になると島の反対側まで来てたが、月はまだ上にあった。皿みたいに涼しい顔でな。"),
("...Then it went and sat in your beak. Typical.", "……结果它跑去坐在了你嘴里。真有它的。", "……それが、お前のくちばしにおさまった。やれやれ、らしいな。"),
("The sun. In a beak.", "太阳，叼在嘴里。", "太陽か。くちばしの中の。"),
("Warm?", "暖和吗？", "あったかかったか？"),
("...warm.", "暖暖的。", "あったかい。"),
("I held it for one second, once. It left a mark.", "我有一回叼了它一秒钟。留了个印子。", "一度だけ、1秒だけくわえたことがある。跡が残った。"),
("...You think these shades are for show?", "……你以为这墨镜只是摆设？", "……このサングラスが飾りだと思ったか？"),
("Straight through a rainbow. Every colour there is, and none of them has a taste.", "一头穿过彩虹。所有的颜色都有，却没一种有味道。", "虹のど真ん中を抜けたか。ありとあらゆる色があって、どれも味がしない。"),
("Strange. You'd think they would.", "怪了。你本以为会有的。", "妙なもんだ。味くらいありそうなのにな。"),
("...it tastes like a rainbow.", "有彩虹的味道。", "虹の味がした。"),
("...Fair.", "……有道理。", "……なるほど。"),
("Cloud, star, sun, moon, rainbow. The whole sky.", "云，星，太阳，月亮，彩虹。整片天空。", "雲、星、太陽、月、虹。空ぜんぶだ。"),
("Nobody gets the whole sky. It's not that kind of thing.", "没人能得到整片天空。它不是那种东西。", "空をまるごと手に入れるやつなんていない。そういうものじゃない。"),
("And you came back down to a roof.", "而你回到的，是一片屋顶。", "それで、お前は屋根に戻ってきた。"),
("...Interesting.", "……有意思。", "……面白い。"),
("Good. The sky didn't get any smaller.", "很好。天空一点没变小。", "よし。空は少しも小さくなってない。"),
("Press E when you want company.", "想找个伴就按 E。", "話し相手がほしけりゃEを押せ。"),
("I'll be here. Without the chain. ...Still looking expensive.", "我就在这儿。没了金链子，……还是看起来很贵。", "おれはここにいる。鎖はなしでな。……それでも高そうだろ。"),
("Wind's good today.", "今天风不错。", "今日は風がいい。"),
("Don't waste it.", "别浪费了。", "無駄にするな。"),
("Mind the old man's table.", "留神老爷子的桌子。", "じいさんのテーブルに気をつけろ。"),
("Not that he'd notice. ...Still.", "倒不是说他会发现。……还是留神点。", "気づかれやしないがな。……それでもだ。"),
("Start small. Work up.", "从小的开始，一点点往上。", "小さいところから始めろ。少しずつ上げていけ。"),
("Everybody does. Even me.", "谁都这样。我也一样。", "誰だってそうだ。おれもな。"),
("The sea looks flat from up here.", "从上面看，大海是平的。", "ここから見ると、海は平らだ。"),
("...It isn't.", "……其实不是。", "……そうじゃないがな。"),
("Chin up, kid. Wings out.", "抬头，小家伙。翅膀张开。", "顔を上げろ、おチビ。翼を広げろ。"),
("The rest is details.", "剩下的都是细节。", "あとは些細なことだ。"),
("I don't give advice.", "我不给人建议。", "おれは助言なんかしない。"),
("...Land softer.", "……落地轻点。", "……もう少しそっと降りろ。"),
("Silver, gold, diamond. The shinier it is, the faster it runs.", "银的，金的，钻石的。越亮的，跑得越快。", "銀、金、ダイヤ。ピカピカなやつほど足が速い。"),
("...Same as most things.", "……大多数东西都这样。", "……たいていのものはそうだ。"),
("The rings shrink when you're nervous.", "你一紧张，圈就缩。", "緊張するとリングが縮む。"),
("That's not a rule. I just noticed.", "这不是规律。我只是注意到了。", "法則じゃない。ただ気づいただけだ。"),
("Roofs are better for resting than trees.", "歇脚，屋顶比树强。", "休むなら、木より屋根だ。"),
("Roofs hold still. Trees gossip.", "屋顶稳得住。树爱嚼舌根。", "屋根は動かない。木はおしゃべりだ。"),
("Notice how a crowd watches your feet, not your face?", "有没有注意到，人群盯的是你的脚，不是你的脸？", "人ごみは顔じゃなく足元を見てるって、気づいたか？"),
("Gulls and thieves, same rule: look innocent from the knees down.", "海鸥和小偷，规矩一样：膝盖以下要看起来无辜。", "カモメも泥棒も同じだ。ひざから下は無実の顔をしておけ。"),
("I had a rule once: never fly with a full beak and an empty head.", "我曾有条规矩：嘴里塞满、脑袋空空，不许起飞。", "昔、ルールを決めた。くちばしがいっぱいで頭が空っぽのときは飛ぶな、と。"),
("...Broke it daily.", "……天天违反。", "……毎日破ってたがな。"),
("The sky isn't empty.", "天空不是空的。", "空は空っぽじゃない。"),
("It's just quiet in places.", "只是有些地方很安静。", "ところどころ静かなだけだ。"),
("You squint like me now. Did you notice?", "你现在眯眼的样子跟我一模一样。发现了吗？", "お前の目の細め方、おれに似てきたぞ。気づいてたか？"),
("I'm not sure either of us should be proud.", "我不确定我们俩谁该为此骄傲。", "どっちも誇れることじゃない気がするがな。"),
("Late in the afternoon the whole pier goes the colour of a fry.", "傍晚，整个码头都会变成薯条的颜色。", "夕方になると、桟橋ぜんぶがポテトの色になる。"),
("...I didn't say that. Forget it.", "……我没说过这话。忘了吧。", "……今のは言ってない。忘れろ。"),
("I knew a gull who only ever ate what fell. Never took a thing.", "我认识一只海鸥，只吃掉下来的东西，从不抢。", "落ちてきたものしか食べないカモメを知ってた。何も奪わないやつだ。"),
("I thought he was a fool.", "我当时觉得他是个傻子。", "バカだと思ってた。"),
("...He always looked fed.", "……可他看上去总是吃饱了的样子。", "……なのに、いつも満ち足りた顔をしてた。"),
("Everything I own, I wear.", "我所有的东西，都穿在身上。", "持ってるものは、ぜんぶ身につけてる。"),
("Funny. It's never the outside that feels heavy.", "怪了，沉的从来不是外面这层。", "妙だな。重いのは、いつも外側じゃない。"),
("I keep a list of everything I have.", "我留着一张清单，写着我拥有的一切。", "持ってるものを、ぜんぶ書き出した表がある。"),
("It's very long. There's a gap near the bottom where something used to be.", "很长。靠近底下有一处空着，原先该有样东西。", "ずいぶん長い。下のほうに、前は何かあった空白がある。"),
("Do you remember what the first one tasted like?", "你还记得第一根是什么味道吗？", "最初の1本は、どんな味だったか覚えてるか？"),
("Warm. Yes.", "暖的。对。", "あったかい。そうだ。"),
("...That's how it starts.", "……一切就是这样开始的。", "……そこから始まるんだ。"),
("I went down to the cafe at dawn. Before the shutters.", "我天亮时去了趟咖啡馆。卷帘门还没拉开。", "夜明けにカフェまで降りてみた。シャッターが開く前にな。"),
("Stood where you stood. The stone is cold in the morning.", "站在你站过的地方。早晨的石头是凉的。", "お前が立ってた場所に立った。朝の石は冷たい。"),
("...I'd forgotten that.", "……我都忘了。", "……忘れてたよ。"),
("That old man. Still drops them?", "那位老爷子，还在掉薯条吗？", "あのじいさん。まだ落としてるのか？"),
("...every morning.", "每天早上。", "毎朝。"),
("Good.", "那就好。", "そうか。いい。"),
("Salt. That's what I remember best now.", "盐味。现在我记得最清楚的就是它。", "塩。今、いちばん覚えてるのはそれだ。"),
("Salt, and a small sound. tk.", "盐味，还有一声轻轻的响。嗒。", "塩と、小さな音。コツ。"),
("Funny. The hat is lighter.", "怪了，帽子轻了。", "妙だな。帽子が軽くなった。"),
("Same hat.", "还是那顶帽子。", "同じ帽子なのにな。"),
("Show me the squint properly.", "把眯眼正经教教我。", "目の細め方、ちゃんと教えてくれ。"),
("...like this.", "这样。", "こう。"),
("Like this?", "这样？", "こうか？"),
("...no.", "不对。", "ちがう。"),
("...I'll practise.", "……我再练练。", "……練習しとく。"),
("It was still warm when it got up here.", "它送到这儿的时候，还是热的。", "ここに着いたとき、まだあったかかった。"),
("...I think about that.", "……我常想起这事。", "……あれを、よく思い出す。"),
("Sit. The view's the same.", "坐。风景还是那个风景。", "座れ。景色は変わらない。"),
("The company isn't.", "陪伴可不一样了。", "連れは、同じじゃないがな。"),
("...That's a lot of hats, kid.", "……帽子可真不少，小家伙。", "……ずいぶんかぶってるな、おチビ。"),
("I'd know.", "我懂的。", "おれには分かる。"),
("...What's that.", "……那是什么。", "……それは何だ。"),
("It doesn't glow.", "它不发光。", "光ってない。"),
("It doesn't make you fast.", "它不会让你变快。", "速くもならない。"),
("...It doesn't do anything.", "……它什么用都没有。", "……何の役にも立たない。"),
("Mine took years to put on.", "我这一身，花了好些年才穿上。", "おれのは、着るのに何年もかかった。"),
("I never tried the other direction.", "反过来脱，我从没试过。", "逆向きは、試したことがない。"),
("...It's the colour I remembered.", "……是我记得的那个颜色。", "……おぼえてた色だ。"),
("You carried it all the way up here.", "你一路把它叼到了这上面。", "ここまで、ずっとくわえてきたのか。"),
("...It's still warm.", "……还是热的。", "……まだ、あったかい。"),
("...Oh.", "……啊。", "……ああ。"),
("Salt.", "盐味。", "塩だ。"),
("I'd forgotten it was this small.", "我都忘了，它这么小。", "こんなに小さかったことを、忘れてた。"),
("he took off the chain. nobody asked him to.", "他把金链子摘了下来。没人要他这么做。", "アニキは鎖を外した。誰も頼んでないのに。"),
("I'm keeping the hat.", "帽子我留着。", "帽子は残す。"),
("...good hat.", "好帽子。", "いい帽子。"),
("...It is a good hat.", "……确实是顶好帽子。", "……いい帽子だよな。"),
("That old man. Does he still drop them?", "那位老爷子，现在还会掉吗？", "あのじいさん、まだ落としてくれるのか？"),
("...Good.", "……那就好。", "……そうか。いい。"),
("hold E: fast-forward", "按住 E：快进", "Eを長押し：早送り"),
]


PAIRS = ("专專 东東 两兩 个個 为為 么麼 云雲 从從 们們 伙夥 会會 体體 俩倆 儿兒 冲衝 凉涼 划劃 别別 单單 卷捲 压壓 发發 变變 后後 吗嗎 响響 垫墊 声聲 处處 头頭 夸誇 奖獎 实實 对對 层層 属屬 岛島 帘簾 当當 总總 愿願 戏戲 抢搶 拥擁 摆擺 数數 无無 时時 机機 条條 来來 柜櫃 树樹 样樣 气氣 没沒 满滿 点點 热熱 爱愛 爷爺 现現 盐鹽 盖蓋 盘盤 眯瞇 着著 码碼 确確 礼禮 种種 稳穩 紧緊 练練 细細 经經 结結 给給 缩縮 脑腦 脚腳 脱脫 脸臉 节節 见見 规規 觉覺 认認 让讓 议議 记記 许許 设設 识識 诉訴 试試 话話 该該 说說 谁誰 谢謝 贵貴 费費 软軟 轻輕 边邊 过過 还還 这這 进進 违違 里裡 钟鐘 钻鑽 银銀 链鏈 错錯 镜鏡 长長 门門 闭閉 问問 闻聞 阳陽 静靜 顶頂 颗顆 颜顏 风風 飞飛 饱飽 饿餓 馆館 骄驕 鸡雞 鸥鷗 专專 于於 开開 却卻 张張 强強 写寫").split()
CMAP = {q[0]: q[1] for q in PAIRS}
PHRASES = [("小家伙", "小傢伙"), ("金链子", "金鍊子"), ("链子", "鍊子")]


def to_tw(s, cmap=CMAP):
    marks = []
    for k, (x, y) in enumerate(PHRASES):
        s = s.replace(x, chr(0xE000 + k))
    out = []
    for i, ch in enumerate(s):
        k = ord(ch) - 0xE000
        if 0 <= k < len(PHRASES):
            out.append(PHRASES[k][1])
        elif ch == "只":
            out.append("隻" if s[i + 1:i + 2] in ("海", "鸟") else "只")
        else:
            out.append(cmap.get(ch, ch))
    return "".join(out)


def main():
    cmap = CMAP
    lines = ["# GENERATED by tools/i18n/gen_r20b.py (round 20: the big brother's new talks, the new ending lines). Do not edit by hand: edit gen_r20b.py.",
             "# (english, simplified chinese, traditional chinese, japanese)", "T = ["]
    for en, zh, ja in ROWS:
        tw = to_tw(zh)
        lines.append("(%r, %r, %r, %r)," % (en, zh, tw, ja))
    lines.append("]")
    out = os.path.join(HERE, "tr_zz_r20b.py")
    open(out, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("wrote", out, len(ROWS), "rows;", len(cmap), "characters in the table")


main()
