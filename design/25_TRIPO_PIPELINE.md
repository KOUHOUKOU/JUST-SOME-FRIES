# 25 — 用 ChatGPT + Tripo 做主角海鸥(及其他素材)的流程与提示词

风格基准图:`JUST_SOME_FRIES/JSF.png`(宣传图)。**每次给 ChatGPT 生图都要附上这张图**,并说 "use only as a style reference"。

## 流程

1. **ChatGPT 生图**:附 JSF.png + 下方提示词 → 得到一张"四视图设定图"(白底)。
2. **挑图**:四个视图的比例必须一致、左右对称。不合格就重生成,别将就(便宜,错了后面全错)。
3. 把设定图发给我 → 我用 Python 裁成 front / left / back / top 四张单图。
4. **Tripo**:用「多视图生成」上传 front / left / back(right 可用 left 镜像)。选「干净拓扑」,纹理可关(只看白模形状),一次生成 3–4 个候选。
5. 挑最好的下载 GLB 给我(下载前我会先问你)。
6. **Blender(我来)**:减面、平面着色(还原 JSF.png 的棱面感)、按肩/肘拆件、划分白/灰/深色翼尖/橙喙四种平色材质、导出。
7. **Godot(我来)**:把 `gull_visual.gd` 里的方盒/球换成这些网格,动画、穿戴品、变色、尾迹全部保留,截图对比。

## 提示词 1:主角海鸥四视图(英文,直接复制)

```
Use the attached image only as a style reference for the seagull's look. Create a character model sheet of that same seagull for a 3D game.

Style: pure flat-shaded low-poly, clearly visible flat polygon facets, chunky simplified shapes, NO feather detail, NO textures, NO outlines, NO painterly shading. Cute, slightly goofy proportions: big rounded head, small black dot eyes, short thick wedge-shaped orange-yellow beak with a small red spot near the tip, plump body, short thin orange-yellow legs with simple flat triangular feet, fan-shaped tail.

Colors: white body and head, light cool-grey wings with dark charcoal wing tips, grey tail, orange-yellow beak and legs.

Pose: wings fully spread, symmetric, gliding pose, slightly angled upward, legs hanging down slightly.

Layout: ONE image, four orthographic views of the SAME bird on a plain pure white background, evenly spaced and aligned: front view, left side view, back view, top-down view. Identical proportions in every view. Perfectly symmetric. Neutral even lighting, no cast shadows, no ground, no text, no labels.
```

## Tripo 设置

- 方式:多视图生成(Multiview → Model)。
- 模式:**干净拓扑**(不选"最高质量",那是写实风)。
- 有面数上限选项就设 **2000–4000 面**。
- 有纹理开关就先关,只要白模;颜色由我们按区域上。
- 先生成 3–4 个候选再挑,点数充足。

## 验收 / 淘汰标准

淘汰:机翼左右不对称、翅膀和身体糊成一团、多腿/缺腿、喙看不清、带写实羽毛、背景残留物、整体圆滚滚没有棱面(棱面感我能在 Blender 补,但形状不对补不了)。

## 其他值得用 Tripo 做的素材(按优先级,先做 ① 即可,其余你点头再做)

| # | 素材 | 为什么值得 | 备注 |
|---|---|---|---|
| ① | **主角海鸥** | 全程都在屏幕上 | 本文流程 |
| ② | **大哥海鸥** | 剧情关键角色 | 同一模型放大/换色,几乎不用额外点数 |
| ③ | **坐着的食客 3–4 种**(情侣、老人、小孩、带薯条的游客) | 抢薯条特写慢镜头里,目前人是胶囊体(`human_rig.gd`),最出戏 | 坐姿静态,不需要绑骨;走路的 NPC 先保持程序化 |
| ④ | 地标:灯塔、摩天轮、风车、咖啡馆 | 宣传图里的招牌画面 | 也可保持程序化,低优先 |
| ⑤ | 薯条盒 / 纸筒 / 盘子 | 抢夺特写会看到 | 薯条本体保持程序化(要按颜色/等级变色发光) |

不建议用 Tripo 做:薯条本体(要变色发光)、14 件穿戴品(要贴合头部挂点)、路面/树/小建筑(数量大,程序化更统一也更省体积)。

### 做其他素材时的统一风格前缀(接在每个提示词前面)

```
Flat-shaded low-poly miniature, visible flat facets, chunky simplified shapes, no texture detail, warm late-afternoon coastal-town palette (terracotta roofs, chalk-white walls, faded blue/coral/sage accents), matches the attached reference image. 
```
