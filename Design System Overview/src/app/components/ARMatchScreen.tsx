import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import confetti from "canvas-confetti";
import { Sparkles, Nfc, RotateCw, Camera, Check, MapPin } from "lucide-react";
import {
  INTERESTS,
  buildMyProfile,
  matchScore,
  commonTags,
  computeSpacetimeRing,
  MY_FOOTPRINTS,
  MOCK_USERS,
  type Profile,
  type MockUser,
} from "../../lib/profile";
import SpacetimeMap from "./SpacetimeMap";

// 与 App 里一致的相册数据（AI「读取照片」的来源）
const albums = [
  { id: "a1", name: "G.E.M", count: 12 },
  { id: "a2", name: "Picslog", count: 48 },
  { id: "a3", name: "做饭", count: 24 },
  { id: "a4", name: "英国", count: 156 },
  { id: "a5", name: "兔子🐶", count: 89 },
];
const PHOTO_TOTAL = albums.reduce((s, a) => s + a.count, 0);
const MY_AVATAR =
  "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200";
// 分析动画用的照片缩略图
const SCAN_PHOTOS = [
  "https://images.unsplash.com/photo-1501786223405-6d024d7c3b8d?q=80&w=200",
  "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?q=80&w=200",
  "https://images.unsplash.com/photo-1647962431451-d0fdaf1cf21c?q=80&w=200",
  "https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=200",
  "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=200",
  "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=200",
];

type Stage = "intro" | "analyzing" | "profile" | "pairing" | "result";

const tag = (k: string) => INTERESTS[k];

// 权重条
function TagBar({ tagKey, weight, delay = 0 }: { tagKey: string; weight: number; delay?: number }) {
  const it = tag(tagKey);
  if (!it) return null;
  return (
    <div className="flex items-center gap-3">
      <div className="w-[68px] flex items-center gap-1.5 shrink-0">
        <span className="text-[16px]">{it.emoji}</span>
        <span className="text-[14px] font-semibold text-[#1C1C1E]">{it.label}</span>
      </div>
      <div className="flex-1 h-2.5 rounded-full bg-black/5 overflow-hidden">
        <motion.div
          className="h-full rounded-full"
          style={{ backgroundColor: it.color }}
          initial={{ width: 0 }}
          animate={{ width: `${Math.round(weight * 100)}%` }}
          transition={{ delay, duration: 0.6, ease: "easeOut" }}
        />
      </div>
      <span className="w-8 text-right text-[12px] font-medium text-[#8E8E93]">
        {Math.round(weight * 100)}
      </span>
    </div>
  );
}

// 环形匹配度
function ScoreRing({ score }: { score: number }) {
  const r = 44;
  const c = 2 * Math.PI * r;
  const color = score >= 80 ? "#34C759" : score >= 60 ? "#0A84FF" : "#FF9F0A";
  return (
    <div className="relative w-[112px] h-[112px]">
      <svg width="112" height="112" className="-rotate-90">
        <circle cx="56" cy="56" r={r} fill="none" stroke="#00000010" strokeWidth="9" />
        <motion.circle
          cx="56" cy="56" r={r} fill="none" stroke={color} strokeWidth="9" strokeLinecap="round"
          strokeDasharray={c}
          initial={{ strokeDashoffset: c }}
          animate={{ strokeDashoffset: c * (1 - score / 100) }}
          transition={{ duration: 1.1, ease: "easeOut" }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <motion.span
          className="text-[32px] font-bold leading-none"
          style={{ color }}
          initial={{ opacity: 0, scale: 0.6 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.3 }}
        >
          {score}
        </motion.span>
        <span className="text-[11px] text-[#8E8E93] mt-0.5">匹配度</span>
      </div>
    </div>
  );
}

export default function ARMatchScreen() {
  const [stage, setStage] = useState<Stage>("intro");
  const [me] = useState<Profile>(() => buildMyProfile(albums));
  const [matched, setMatched] = useState<MockUser | null>(null);
  const [score, setScore] = useState(0);
  const pairCount = useRef(0);

  useEffect(() => {
    if (stage === "analyzing") {
      const t = setTimeout(() => setStage("profile"), 2600);
      return () => clearTimeout(t);
    }
    if (stage === "pairing") {
      const t = setTimeout(() => {
        const next = MOCK_USERS[pairCount.current % MOCK_USERS.length];
        pairCount.current += 1;
        setMatched(next);
        setScore(matchScore(me, next.profile));
        setStage("result");
      }, 2000);
      return () => clearTimeout(t);
    }
  }, [stage, me]);

  useEffect(() => {
    if (stage === "result" && score >= 60) {
      confetti({ particleCount: 90, spread: 75, origin: { y: 0.4 }, scalar: 0.9 });
    }
  }, [stage, score]);

  const common = matched ? commonTags(me, matched.profile) : [];
  const verdict =
    score >= 80 ? "灵魂绝配 ✨" : score >= 60 ? "同频共振 🎯" : "缘分尚浅，再碰碰看";

  // 时空环：两人共同去过的地点 + 时间擦肩
  const spacetime = matched ? computeSpacetimeRing(MY_FOOTPRINTS, matched.footprints) : [];
  const brushedCount = spacetime.filter((s) => s.brushed).length;
  const ringText = spacetime.length
    ? `你们曾在 ${spacetime.length} 个地方相遇${brushedCount ? `，其中 ${brushedCount} 次擦肩而过` : ""}`
    : "你们还没有共同去过的地方";

  return (
    <div className="relative w-full h-full bg-[#F5F4F1] -mt-14 pt-14 overflow-hidden">
      <AnimatePresence mode="wait">
        {/* —— 入口 —— */}
        {stage === "intro" && (
          <motion.div
            key="intro"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="absolute inset-0 pt-14 px-6 flex flex-col items-center justify-center text-center"
          >
            <motion.div
              animate={{ scale: [1, 1.08, 1], rotate: [0, 6, -6, 0] }}
              transition={{ duration: 3, repeat: Infinity }}
              className="w-24 h-24 rounded-3xl bg-gradient-to-br from-[#0A84FF] to-[#BF5AF2] flex items-center justify-center shadow-lg mb-7"
            >
              <Sparkles className="w-11 h-11 text-white" />
            </motion.div>
            <h1 className="text-[26px] font-bold text-[#1C1C1E] mb-2">AI 照片画像</h1>
            <p className="text-[15px] text-[#8E8E93] leading-relaxed mb-10 max-w-[260px]">
              让 AI 读懂你拍下的世界，生成专属兴趣画像，碰一碰找到同频的人
            </p>
            <button
              onClick={() => setStage("analyzing")}
              className="w-full max-w-[300px] h-[52px] rounded-2xl bg-[#1C1C1E] text-white font-semibold text-[16px] flex items-center justify-center gap-2 active:scale-[0.98] transition-transform"
            >
              <Camera className="w-5 h-5" />
              开始分析我的照片
            </button>
          </motion.div>
        )}

        {/* —— 分析中 —— */}
        {stage === "analyzing" && (
          <motion.div
            key="analyzing"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="absolute inset-0 pt-14 px-6 flex flex-col items-center justify-center"
          >
            <div className="grid grid-cols-3 gap-2 mb-8">
              {SCAN_PHOTOS.map((src, i) => (
                <motion.div
                  key={i}
                  className="w-[72px] h-[72px] rounded-xl overflow-hidden"
                  animate={{ opacity: [0.3, 1, 0.3], scale: [0.95, 1, 0.95] }}
                  transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.15 }}
                >
                  <img src={src} className="w-full h-full object-cover" />
                </motion.div>
              ))}
            </div>
            <motion.div
              className="flex items-center gap-2 text-[#0A84FF] mb-2"
              animate={{ opacity: [0.5, 1, 0.5] }} transition={{ duration: 1.4, repeat: Infinity }}
            >
              <Sparkles className="w-5 h-5" />
              <span className="text-[16px] font-semibold">AI 正在分析你的 {PHOTO_TOTAL} 张照片…</span>
            </motion.div>
            <p className="text-[13px] text-[#8E8E93]">识别场景 · 提取兴趣 · 生成画像</p>
          </motion.div>
        )}

        {/* —— 我的画像 —— */}
        {stage === "profile" && (
          <motion.div
            key="profile"
            initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}
            className="absolute inset-0 pt-16 px-5 pb-28 flex flex-col"
          >
            <div className="flex flex-col items-center mb-6">
              <div className="w-20 h-20 rounded-full border-[3px] border-white shadow-md overflow-hidden mb-3">
                <img src={MY_AVATAR} className="w-full h-full object-cover" />
              </div>
              <div className="px-3 py-1 rounded-full bg-[#1C1C1E] text-white text-[13px] font-semibold mb-1">
                {me.persona}
              </div>
              <p className="text-[12px] text-[#8E8E93]">基于 {PHOTO_TOTAL} 张照片 · AI 生成</p>
            </div>

            <div className="bg-white rounded-2xl p-4 shadow-sm flex flex-col gap-3 mb-auto">
              <span className="text-[13px] font-semibold text-[#8E8E93]">兴趣画像</span>
              {me.topTags.map((k, i) => (
                <TagBar key={k} tagKey={k} weight={me.weights[k]} delay={i * 0.08} />
              ))}
            </div>

            <button
              onClick={() => setStage("pairing")}
              className="mt-6 w-full h-[54px] rounded-2xl bg-gradient-to-r from-[#0A84FF] to-[#5E5CE6] text-white font-semibold text-[16px] flex items-center justify-center gap-2 active:scale-[0.98] transition-transform shadow-lg shadow-blue-500/20"
            >
              <Nfc className="w-5 h-5" />
              碰一碰，找同频的人
            </button>
          </motion.div>
        )}

        {/* —— NFC 碰一碰 —— */}
        {stage === "pairing" && (
          <motion.div
            key="pairing"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="absolute inset-0 pt-14 flex flex-col items-center justify-center"
          >
            <div className="relative flex items-center justify-center mb-10">
              {/* 两个头像从两侧靠近 */}
              <motion.div
                className="w-16 h-16 rounded-full border-[3px] border-white shadow-md overflow-hidden z-10"
                initial={{ x: -70 }} animate={{ x: -28 }}
                transition={{ duration: 1, repeat: Infinity, repeatType: "reverse", ease: "easeInOut" }}
              >
                <img src={MY_AVATAR} className="w-full h-full object-cover" />
              </motion.div>
              <motion.div
                className="w-16 h-16 rounded-full border-[3px] border-white shadow-md overflow-hidden z-10 bg-gray-200"
                initial={{ x: 70 }} animate={{ x: 28 }}
                transition={{ duration: 1, repeat: Infinity, repeatType: "reverse", ease: "easeInOut" }}
              >
                <img src={MOCK_USERS[pairCount.current % MOCK_USERS.length].avatar} className="w-full h-full object-cover" />
              </motion.div>
              {/* 中间 NFC 波纹 */}
              {[0, 1, 2].map((i) => (
                <motion.div
                  key={i}
                  className="absolute w-16 h-16 rounded-full border-2 border-[#0A84FF]"
                  animate={{ scale: [1, 2.4], opacity: [0.6, 0] }}
                  transition={{ duration: 1.6, repeat: Infinity, delay: i * 0.5 }}
                />
              ))}
              <div className="absolute z-20 w-9 h-9 rounded-full bg-[#0A84FF] flex items-center justify-center shadow-lg">
                <Nfc className="w-5 h-5 text-white" />
              </div>
            </div>
            <span className="text-[16px] font-semibold text-[#1C1C1E]">正在碰一碰…</span>
            <p className="text-[13px] text-[#8E8E93] mt-1">寻找与你同频的灵魂</p>
          </motion.div>
        )}

        {/* —— 匹配结果 —— */}
        {stage === "result" && matched && (
          <motion.div
            key="result"
            initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}
            className="absolute inset-0 pt-16 pb-24 flex flex-col"
          >
            <div className="flex-1 overflow-y-auto px-5 flex flex-col items-center scrollbar-hide">
              {/* 双方头像 */}
              <div className="flex items-center gap-3 mb-2">
                <div className="w-12 h-12 rounded-full border-[3px] border-white shadow overflow-hidden">
                  <img src={MY_AVATAR} className="w-full h-full object-cover" />
                </div>
                <motion.div
                  initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ delay: 0.5, type: "spring" }}
                  className="w-7 h-7 rounded-full bg-[#FF6B6B] flex items-center justify-center text-white text-[13px]"
                >
                  ♥
                </motion.div>
                <div className="w-12 h-12 rounded-full border-[3px] border-white shadow overflow-hidden">
                  <img src={matched.avatar} className="w-full h-full object-cover" />
                </div>
              </div>

              <ScoreRing score={score} />

              <h2 className="text-[19px] font-bold text-[#1C1C1E] mt-1.5">{verdict}</h2>
              <p className="text-[13px] text-[#8E8E93] mb-3">
                与 <span className="font-semibold text-[#1C1C1E]">{matched.name}</span>（{matched.profile.persona}）
              </p>

              {/* 比邻环：共同兴趣标签 */}
              {common.length > 0 && (
                <div className="w-full bg-white rounded-2xl p-3.5 shadow-sm mb-2.5">
                  <span className="text-[13px] font-semibold text-[#8E8E93]">比邻环 · 共同兴趣</span>
                  <div className="flex flex-wrap gap-2 mt-3">
                    {common.map((k) => (
                      <div
                        key={k}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[13px] font-semibold text-white"
                        style={{ backgroundColor: tag(k).color }}
                      >
                        <span>{tag(k).emoji}</span>
                        <span>{tag(k).label}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* 时空环：共同去过的地点 + 时间擦肩 */}
              <div className="w-full bg-white rounded-2xl p-4 shadow-sm">
                <div className="flex items-center gap-1.5 mb-1">
                  <MapPin className="w-4 h-4 text-[#0A84FF]" />
                  <span className="text-[14px] font-bold text-[#1C1C1E]">时空环 · 你们的交集</span>
                </div>
                <p className="text-[12px] text-[#8E8E93] mb-3">{ringText}</p>

                {/* 南京足迹叠加地图：共同点高亮 */}
                <SpacetimeMap mine={MY_FOOTPRINTS} theirs={matched.footprints} />
                <div className="flex items-center gap-4 mt-2 mb-3 text-[11px] text-[#8E8E93]">
                  <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded-full bg-[#0A84FF] inline-block" />你的足迹</span>
                  <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded-full bg-[#FF6B6B] inline-block" />TA 的足迹</span>
                  <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-full border-2 border-[#FF6B6B] inline-block" />擦肩点</span>
                </div>

                {spacetime.length > 0 ? (
                  <div className="flex flex-col gap-3">
                    {spacetime.map((s) => (
                      <div key={s.place} className="flex items-center gap-3">
                        {/* 两人照片叠合 */}
                        <div className="relative w-[52px] h-9 shrink-0">
                          <img src={s.photo} className="absolute left-0 top-0 w-9 h-9 rounded-full border-2 border-white object-cover" />
                          <img src={s.photo} className="absolute left-[16px] top-0 w-9 h-9 rounded-full border-2 border-[#0A84FF] object-cover" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="text-[14px] font-semibold text-[#1C1C1E]">{s.name}</div>
                          <div className="text-[12px] text-[#8E8E93]">你 {s.myMonth} 月 · TA {s.otherMonth} 月</div>
                        </div>
                        {s.brushed ? (
                          <span className="px-2 py-1 rounded-full bg-[#FF6B6B] text-white text-[11px] font-semibold shrink-0">擦肩而过</span>
                        ) : (
                          <span className="px-2 py-1 rounded-full bg-black/5 text-[#8E8E93] text-[11px] font-medium shrink-0">相差 {s.gap} 月</span>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-[13px] text-[#8E8E93]">还没有共同去过的地方，去南京多拍点照片吧</p>
                )}
              </div>
            </div>

            {/* 底部按钮 */}
            <div className="px-5 pt-3 flex gap-3">
              <button
                onClick={() => setStage("profile")}
                className="flex-1 h-[50px] rounded-2xl bg-black/5 text-[#1C1C1E] font-semibold text-[15px] flex items-center justify-center gap-1.5 active:scale-[0.98] transition-transform"
              >
                <Check className="w-4 h-4" /> 完成
              </button>
              <button
                onClick={() => setStage("pairing")}
                className="flex-1 h-[50px] rounded-2xl bg-[#1C1C1E] text-white font-semibold text-[15px] flex items-center justify-center gap-1.5 active:scale-[0.98] transition-transform"
              >
                <RotateCw className="w-4 h-4" /> 再碰一个
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
