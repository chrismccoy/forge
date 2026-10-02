// Classic vs block theme screenshot comparison (Playwright Test).
//
// 1. Activate the classic theme:   SITE_URL=https://staging.example.com npx playwright test --update-snapshots
// 2. Activate the block theme:     SITE_URL=https://staging.example.com npx playwright test
// Failures write diff images to test-results/. Add every template type and CPT the site uses.
const { test, expect } = require( '@playwright/test' );

const BASE = process.env.SITE_URL || 'http://localhost:8888';

const PAGES = [
	[ 'home', '/' ],
	[ 'single', '/hello-world/' ],
	[ 'page', '/sample-page/' ],
	[ 'archive', '/category/uncategorized/' ],
	[ 'search', '/?s=hello' ],
	[ '404', '/this-page-does-not-exist/' ],
	[ 'event-single', '/events/sample-event/' ],
	[ 'event-archive', '/events/' ],
];

const WIDTHS = [ 375, 768, 1280 ];

for ( const [ name, path ] of PAGES ) {
	for ( const width of WIDTHS ) {
		test( `${ name } @ ${ width }px`, async ( { page } ) => {
			await page.setViewportSize( { width, height: 900 } );
			await page.goto( BASE + path, { waitUntil: 'networkidle' } );
			await expect( page ).toHaveScreenshot( `${ name }-${ width }.png`, {
				fullPage: true,
				animations: 'disabled',
				maxDiffPixelRatio: 0.02, // Tolerate antialiasing; tighten once parity is close.
				mask: [ page.locator( 'time' ), page.locator( '#wpadminbar' ) ], // Volatile regions.
			} );
		} );
	}
}
