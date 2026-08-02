import {
  METERS_PER_SEGMENT,
  automationDamagePerSecond,
  criticalChance,
  criticalMultiplier,
  recommendMiningUpgrade,
  refinementCost,
  refinementMultiplier,
  segmentIntegrity,
  segmentOre,
  tapDamage,
  unlockedMaximumLevel,
  upgradeCost,
} from "./coreBalance.js";

const initial = () => ({ depth: 8, ore: 100, damage: 0, equipment: { drill: 1, cart: 1, lamp: 1 } });
let state = initial();
const format = (value) => Number.isFinite(value)
  ? new Intl.NumberFormat("ko-KR", { maximumFractionDigits: value < 100 ? 2 : 0 }).format(value)
  : "∞";

function applyDamage(amount) {
  state.damage += amount;
  while (state.damage >= segmentIntegrity(Math.floor(state.depth / METERS_PER_SEGMENT))) {
    const index = Math.floor(state.depth / METERS_PER_SEGMENT);
    state.damage -= segmentIntegrity(index);
    state.ore += segmentOre(index);
    state.depth += METERS_PER_SEGMENT;
  }
}

function buyRecommended() {
  const kind = recommendMiningUpgrade(state.equipment, state.ore, state.depth);
  if (!kind) return;
  const cost = upgradeCost(kind, state.equipment[kind]);
  if (cost != null && cost <= state.ore) {
    state.ore -= cost;
    state.equipment[kind] += 1;
  }
}

function render() {
  const dps = automationDamagePerSecond(state.equipment.cart);
  const recommendation = recommendMiningUpgrade(state.equipment, state.ore, state.depth);
  document.querySelector("#readout").innerHTML = [
    `심도: ${state.depth}m`, `광석: ${format(state.ore)}`,
    `장비: 드릴 ${state.equipment.drill} / 광차 ${state.equipment.cart} / 램프 ${state.equipment.lamp}`,
    `탭: ${format(tapDamage(state.equipment.drill))}`, `자동 DPS: ${format(dps)}`,
    `추천: ${recommendation ?? "구매 가능 장비 없음"}`,
  ].join("<br>");
}

const checks = [
  ["모든 장비는 Lv.1에서 시작", () => initial().equipment.cart === 1],
  ["광차 Lv.1은 자동 DPS 0", () => automationDamagePerSecond(1) === 0],
  ["광차 Lv.2부터 자동화 시작", () => automationDamagePerSecond(2) > 0],
  ["초기 100 광석에서는 드릴만 구매 가능", () => recommendMiningUpgrade(initial().equipment, 100, 8) === "drill"],
  ["광차 비용 확보 시 첫 자동화를 최우선 추천", () => recommendMiningUpgrade(initial().equipment, 180, 15) === "cart"],
  ["장비 상한 200 제거", () => upgradeCost("drill", 201) !== null],
  ["정련은 6레벨마다 해금되고 ×2.5", () => refinementMultiplier(1) === 2.5],
  ["정련 비용은 해금 레벨 장비 비용의 20배", () => refinementCost("drill", 1) === Math.ceil(upgradeCost("drill", 7) * 20)],
  ["램프 정련은 크리티컬 배수에 적용", () => criticalMultiplier(1, 2) > criticalMultiplier(1, 0)],
  ["심도 240m에서 구매 가능 레벨 17", () => unlockedMaximumLevel(240) === 17],
  ["초기 크리티컬 확률은 5%", () => criticalChance(1) === 0.05],
];
const results = checks.map(([name, run]) => ({ name, passed: Boolean(run()) }));
document.querySelector("#checks").innerHTML = results.map(({ name, passed }) =>
  `<li class="${passed ? "pass" : "fail"}">${passed ? "PASS" : "FAIL"} · ${name}</li>`).join("");
const passed = results.filter((result) => result.passed).length;
const status = document.querySelector("#status");
status.textContent = `${passed}/${results.length} 로직 검증 통과`;
status.classList.add(passed === results.length ? "ok" : "fail");
document.querySelector("#metrics").innerHTML = [
  ["초기 탭", tapDamage(1)], ["첫 자동 DPS", automationDamagePerSecond(2)],
  ["첫 정련", `×${refinementMultiplier(1)}`], ["첫 광차 비용", upgradeCost("cart", 1)],
].map(([label, value]) => `<div class="metric">${label}<strong>${format(value)}</strong></div>`).join("");

document.querySelector("#mine").addEventListener("click", () => { applyDamage(tapDamage(state.equipment.drill)); render(); });
document.querySelector("#upgrade").addEventListener("click", () => { buyRecommended(); render(); });
document.querySelector("#reset").addEventListener("click", () => { state = initial(); render(); });
render();
