import type { Metadata } from "next";
import { UnifiedMinePrototype } from "./UnifiedMinePrototype";

export const metadata: Metadata = {
  title: "DeepMine — 통합 성장 로직",
  description: "iOS DeepMineCore와 동일한 암반, 장비, 자동화, 정련 규칙을 실행하는 웹 프로토타입",
};

export default function Home() {
  return <UnifiedMinePrototype />;
}
