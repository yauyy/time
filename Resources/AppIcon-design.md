# Time 图标设计

- 当前版本：1.0.3 / build 4
- 当前素材：`Resources/AppIcon.png`（1254×1254 RGBA）
- 生成方式：内置 imagegen；用户已同意不限定底层模型，未声称使用 GPT Image 2。
- 主体：时钟、指针、简洁环绕轨道，直接表达国际时间。
- 画风：清爽的二维赛璐璐线条和明暗，保持小尺寸辨识度。
- 最终颜色：月白、银灰、低饱和蓝灰；已按用户反馈去掉大面积高饱和蓝色。
- 透明度：PNG 保留外部 alpha；UI 直接读取原始 PNG，不添加灰色底板或图标底块。
- 应用 UI 继续跟随 macOS 系统强调色及浅深外观。
- 图标不再使用猫咪、猫爪、耳朵或其他角色；旧版设计说明见 `AppIcon-design-1.0.1.md`，仅作历史。

## 初次生成提示词（高饱和版本未部署）

Use case: stylized-concept. Create one polished macOS application icon for Time, an international menu-bar clock. The unmistakable main subject must be a clock, rendered as refined original Japanese anime cel illustration. A front-facing circular ivory clock face, with two bold midnight-blue hands at 10:10, a small central pivot, four simple hour marks, and a softly beveled cobalt-blue rim. One thin restrained orbit arc integrated behind the rim subtly suggests world time. Style: confident clean ink-like contours, elegant broad shapes, crisp two-tone cel shading, a little soft illustrated highlight and gentle depth, contemporary and calm. The anime sensibility comes entirely from the drawing style. Composition: one centered emblem filling most of a clean blue macOS rounded-square icon tile, square 1024x1024 master, strong silhouette and contrast at 16px and 32px. Keep the design uncluttered and instantly recognizable as a time utility. The tile occupies about 90 percent of the image and has fully transparent outer corners and margins. Absolutely no separate gray backplate, no gray matte, no surrounding shadow plate, no extra frame, no checkerboard. The clock face is opaque, the tile is opaque, transparency only outside the rounded square. No cats, no animals, no faces, no ears, no paws, no mascot, no people, no characters, no text, no letters, no numbers, no watermark, no scene, no decorative clutter, no glossy plastic 3D. Deliver only the finished icon.

## 最终定向编辑提示词

Edit this existing Time application icon. Preserve the exact clock subject, composition, circular clock face, two hands at 10:10, four hour marks, orbit arc, rounded-square tile shape, clean cel-illustrated style, and transparent outside corners/margins. Change only the palette and the corresponding material shading. The current saturated cobalt and electric blue is far too strong. Replace the large blue regions with quiet, low-saturation pearl white, soft silver, and misty blue-gray. The rounded-square tile should be near-white ivory with a very subtle neutral cool-gray shading, not a big blue color field. The clock rim should be a restrained desaturated slate blue-gray, predominantly gray, with soft pale-silver highlights. Hands and fine contours should remain dark charcoal blue-gray for excellent small-size readability. The clock face stays warm ivory. Orbit arc is pale silver-white, with enough contrast to remain visible. Overall impression: airy, gentle, elegant, neutral, understated, and refined. Saturation must be very low across almost the entire image; no vivid blue gradients, no cyan, no purple color cast, no gold or bright accents. Keep the returned PNG's existing transparency outside the tile. Do not add any gray backing plate behind or outside the rounded square, no extra frame, no surrounding shadow, no scenery. No cats, animals, faces, people, text, letters, numerals, or watermark. Deliver the single finished icon.
