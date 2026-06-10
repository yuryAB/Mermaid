import { expect, test, type Page } from '@playwright/test';

const states = [
  ['idle', async (page: Page) => page.getByRole('button', { name: 'Calm', exact: true }).click()],
  ['up', async (page: Page) => page.keyboard.down('ArrowUp')],
  ['down', async (page: Page) => page.keyboard.down('ArrowDown')],
  ['left', async (page: Page) => page.keyboard.down('ArrowLeft')],
  ['right', async (page: Page) => page.keyboard.down('ArrowRight')],
  ['swing', async (page: Page) => page.getByRole('button', { name: 'Swim', exact: true }).click()],
  ['fast', async (page: Page) => page.getByRole('button', { name: 'Fast', exact: true }).click()]
] as const;

for (const [stateName, applyState] of states) {
  test(`${stateName} visual state`, async ({ page }) => {
    await page.goto('/?debug=1&stable=1');
    await expect(page.locator('canvas')).toBeVisible();
    await page.waitForFunction(() => Boolean((window as Window & { __MERMAID_RIG__?: unknown }).__MERMAID_RIG__));
    await applyState(page);
    await page.waitForTimeout(700);
    await expect(page).toHaveScreenshot(`mermaid-${stateName}.png`, {
      animations: 'disabled',
      fullPage: false,
      timeout: 15_000
    });
  });
}
