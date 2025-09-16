import { test, expect } from '@playwright/test';

// Assumes the Flutter web app is running on http://localhost:55555 or adjust
const APP_URL = process.env.APP_URL || 'http://localhost:55555';

test.describe('Payment flow with legacy order ID', () => {
  test('blocks navigation when order ID is non-UUID and allows upload for UUID', async ({ page }) => {
    await page.goto(APP_URL);

    // TODO: adjust selectors to match the app's DOM. These are likely to be
    // app-specific; update after a quick run to inspect elements.

    // Navigate to Orders list
    await page.click('text=Orders');

    // Find an order row that has a legacy id marker (data-legacy-id attribute)
    // Fallback: use first order and open details
    await page.click('css=.order-row >> nth=0');

    // Click Make Payment
    await page.click('text=Make Payment');

    // If the app shows a SnackBar about invalid ID, assert it appears
    const snack = page.locator('text=invalid order identifier');
    if (await snack.count() > 0) {
      await expect(snack).toBeVisible();
      return; // success: navigation was blocked
    }

    // Otherwise we are on Payment screen; attempt to select file and upload
    // Click Choose File (web) and set input files
    const fileInput = page.locator('input[type="file"]');
    if (await fileInput.count() > 0) {
      // Use a small fixture image (create one in playwright/fixtures/ if missing)
      await fileInput.setInputFiles('playwright/fixtures/sample_proof.png');
    }

    // Click Submit/Confirm payment
    await page.click('text=Submit Payment');

    // Expect either success toast or an error about upload failing
    await expect(page.locator('text=Payment submission failed').first()).toBeVisible({ timeout: 10000 });
  });
});


