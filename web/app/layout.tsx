import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "DeepMine",
    template: "%s · DeepMine",
  },
  description: "가운데를 파고 내려가는 픽셀 광산",
  themeColor: "#0a0a09",
  openGraph: {
    title: "DeepMine — 연속 갱도 프로토타입",
    description: "지나온 균열과 설비가 위에 쌓이고, 광부가 큰 지층의 가운데를 뚫고 내려갑니다.",
    images: [
      {
        url: "/og/deepmine-shaft-social.png",
        width: 1730,
        height: 909,
        alt: "큰 지층의 가운데를 파고 내려가는 DeepMine 광부",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    images: ["/og/deepmine-shaft-social.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
