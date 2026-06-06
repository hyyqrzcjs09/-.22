import { SlidersHorizontal } from "lucide-react";
import { useState } from "react";
import { ImageWithFallback } from "./figma/ImageWithFallback";

interface YearData {
  year: string;
  label: string;
  count: number;
  photos: string[];
}

export default function AlbumView() {
  const [selectedYear, setSelectedYear] = useState("今年");

  const yearData: YearData[] = [
    { 
      year: "2026", 
      label: "今年", 
      count: 12, 
      photos: [
        "https://images.unsplash.com/photo-1528699633788-424224dc89b5?w=400",
        "https://images.unsplash.com/photo-1676564595913-dca5bed75cc3?w=400",
        "https://images.unsplash.com/photo-1699730164892-d7c433524ff3?w=400",
        "https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400",
        "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400",
        "https://images.unsplash.com/photo-1513061379709-ef0cd1695189?w=400",
      ]
    },
    { 
      year: "2025", 
      label: "1年前", 
      count: 9, 
      photos: [
        "https://images.unsplash.com/photo-1501786223405-6d024d7c3b8d?w=400",
        "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400",
        "https://images.unsplash.com/photo-1647962431451-d0fdaf1cf21c?w=400",
      ]
    },
    { year: "2024", label: "2年前", count: 11, photos: [] },
    { year: "2023", label: "3年前", count: 8, photos: [] },
    { year: "2022", label: "4年前", count: 15, photos: [] },
    { year: "2021", label: "5年前", count: 6, photos: [] },
    { year: "2020", label: "6年前", count: 4, photos: [] },
  ];

  const selectedData = yearData.find(d => d.label === selectedYear);

  return (
    <div className="absolute inset-0 pt-[44px] pb-[124px] overflow-y-auto" style={{ backgroundColor: 'var(--app-bg-gray)' }}>
      <div className="px-4 pt-4">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <h1 style={{ fontSize: 'var(--app-text-hero)', fontWeight: 700, color: 'var(--app-text-primary)' }}>
            12月17日
          </h1>
          <button 
            className="bg-white rounded-full flex items-center justify-center"
            style={{ width: '44px', height: '44px', boxShadow: 'var(--app-shadow-soft)' }}
          >
            <SlidersHorizontal size={20} style={{ color: 'var(--app-text-primary)' }} />
          </button>
        </div>

        {/* Year Selector */}
        <div className="flex gap-4 overflow-x-auto mb-6 pb-2 scrollbar-hide">
          {yearData.map((item) => {
            const isActive = selectedYear === item.label;
            return (
              <button
                key={item.label}
                onClick={() => setSelectedYear(item.label)}
                className="flex-shrink-0 relative pb-1"
              >
                <span
                  style={{
                    fontSize: 'var(--app-text-body)',
                    fontWeight: isActive ? 700 : 400,
                    color: isActive ? 'var(--app-text-primary)' : 'var(--app-text-secondary)',
                    position: 'relative',
                  }}
                >
                  {item.label}
                  <sup style={{ fontSize: 'var(--app-text-superscript)', fontWeight: 500 }}>
                    {item.count}
                  </sup>
                </span>
                {isActive && (
                  <div 
                    className="absolute bottom-0 left-0 right-0 h-[2px] bg-[var(--app-text-primary)]"
                    style={{ width: '60%', margin: '0 auto' }}
                  />
                )}
              </button>
            );
          })}
        </div>

        {/* Photos Grid by Year */}
        {selectedData && (
          <>
            <h2 
              className="mb-3"
              style={{ 
                fontSize: 'var(--app-text-body)', 
                fontWeight: 600, 
                color: 'var(--app-text-primary)' 
              }}
            >
              {selectedData.year}
            </h2>

            <div className="grid grid-cols-3 gap-[2px] mb-6">
              {selectedData.photos.length > 0 ? (
                selectedData.photos.map((photo, index) => (
                  <div 
                    key={index}
                    className="aspect-square rounded-sm overflow-hidden"
                    style={{ backgroundColor: '#E5E5EA' }}
                  >
                    <ImageWithFallback 
                      src={photo}
                      alt={`Photo ${index + 1}`}
                      className="w-full h-full object-cover"
                    />
                  </div>
                ))
              ) : (
                [...Array(selectedData.count)].map((_, index) => (
                  <div 
                    key={index}
                    className="aspect-square rounded-sm"
                    style={{ backgroundColor: '#E5E5EA' }}
                  />
                ))
              )}
            </div>
          </>
        )}

        {/* Previous Years */}
        {yearData
          .filter(d => d.year < (selectedData?.year || "0"))
          .map((yearGroup) => (
            <div key={yearGroup.year} className="mb-6">
              <h2 
                className="mb-3"
                style={{ 
                  fontSize: 'var(--app-text-body)', 
                  fontWeight: 600, 
                  color: 'var(--app-text-primary)' 
                }}
              >
                {yearGroup.year}
              </h2>
              <div className="grid grid-cols-3 gap-[2px]">
                {[...Array(Math.min(6, yearGroup.count))].map((_, index) => (
                  <div 
                    key={index}
                    className="aspect-square rounded-sm"
                    style={{ backgroundColor: '#E5E5EA' }}
                  />
                ))}
              </div>
            </div>
          ))}

        {/* Loading Complete Text */}
        <div className="text-center py-6">
          <p style={{ fontSize: 'var(--app-text-caption)', color: 'var(--app-text-secondary)' }}>
            数据加载已完成
          </p>
        </div>
      </div>
    </div>
  );
}
