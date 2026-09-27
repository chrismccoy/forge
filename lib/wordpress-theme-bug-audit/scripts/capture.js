/*
 * Error and accessibility capture for `shot`: pass the contents as SHOT_INIT_JS.
 *   SHOT_INIT_JS="$(cat capture.js)" shot <url> <file.png> [width] [height]
 *
 * `shot` returns only an image, so findings are sent as requests the test server logs:
 *   /__jserr?p=<page>&m=<message>   JS errors, unhandled rejections, console.error calls, failed resources
 *   /__axe?p=<page>&m=<rule>|<impact>|<nodes>|<first target>   axe-core violations (needs /axe.min.js in the web root)
 *   /__axedone?p=<page>&m=<count>   axe finished
 *   /__axetimeout?p=<page>&m=<ms>   axe hadn't finished this long after load (shot captures about 3 s after load);
 *                                    run it again on one region with __AUDIT_AXE_CONTEXT
 * Summarize them with: python3 jslog.py <tmp>/server.log
 *
 * Prepend `window.__AUDIT_NOAXE = 1;` to skip axe, or `window.__AUDIT_AXE_CONTEXT = 'main';` to limit it to one region.
 * Prepend `window.__AUDIT_AXE_TIMEOUT_MS = <ms>;` to change when axetimeout is sent (default 2500, just under the
 * ~3 s `shot` waits after load; a longer value only helps with a slower capture). A timeout is never reported as axedone.
 * Append page-specific interaction code (clicks, key presses) after this file; send its results with window.__auditSend.
 * Including this file twice is harmless: the second copy does nothing.
 */
(function () {
	'use strict';

	if (window.__AUDIT_CAPTURE_INSTALLED) {
		return;
	}
	window.__AUDIT_CAPTURE_INSTALLED = true;

	const MAX_MESSAGE_LENGTH = 300;
	const AXE_SCRIPT_URL = '/axe.min.js';
	// Just under the ~3 s `shot` waits after load, so the timeout report reaches the log before the capture.
	const DEFAULT_AXE_TIMEOUT_MS = 2500;

	/**
	 * Reports a finding to the test server via a beacon-style image request.
	 * @param {string} kind - Endpoint suffix, e.g. 'jserr', 'axe', 'axedone'.
	 * @param {*} message - Any value; coerced to string and truncated.
	 */
	function send(kind, message) {
		try {
			const page = encodeURIComponent(location.pathname + location.search);
			const msg = encodeURIComponent(String(message).slice(0, MAX_MESSAGE_LENGTH));
			new Image().src = `/__${kind}?p=${page}&m=${msg}`;
		} catch (e) {
			// Reporting must never throw and break the page under audit.
		}
	}
	window.__auditSend = send;

	function describeError(event) {
		const target = event.target;
		const resourceUrl = target && target !== window && (target.src || target.href);
		if (resourceUrl) {
			return `resource failed ${resourceUrl}`;
		}
		return `${event.message || ''} @${event.filename || ''}:${event.lineno || ''}`;
	}

	function describeRejection(event) {
		const reason = event.reason;
		const detail = reason && (reason.message || reason);
		return `rejection ${detail}`;
	}

	function installErrorCapture() {
		window.addEventListener(
			'error',
			(e) => send('jserr', describeError(e)),
			true // capture phase: also catches resource load failures (img/script/link)
		);

		window.addEventListener('unhandledrejection', (e) => {
			send('jserr', describeRejection(e));
		});

		const originalConsoleError = console.error;
		console.error = function (...args) {
			send('jserr', `console.error ${args.join(' ')}`);
			return originalConsoleError.apply(console, args);
		};
	}

	function loadScript(src) {
		return new Promise((resolve, reject) => {
			const script = document.createElement('script');
			script.src = src;
			script.onload = resolve;
			script.onerror = () => reject(new Error(`failed to load ${src}`));
			document.head.appendChild(script);
		});
	}

	async function runAxeAudit() {
		if (window.__AUDIT_NOAXE) {
			return;
		}
		const timeoutMs = window.__AUDIT_AXE_TIMEOUT_MS || DEFAULT_AXE_TIMEOUT_MS;
		const timeout = setTimeout(() => send('axetimeout', timeoutMs), timeoutMs);
		try {
			await loadScript(AXE_SCRIPT_URL);
			const context = window.__AUDIT_AXE_CONTEXT || document;
			const results = await axe.run(context, { resultTypes: ['violations'] });

			results.violations.forEach((violation) => {
				const firstTarget = violation.nodes[0]?.target.join(' ') || '';
				send(
					'axe',
					`${violation.id}|${violation.impact}|${violation.nodes.length}|${firstTarget}`
				);
			});

			send('axedone', results.violations.length);
		} catch (err) {
			send('jserr', `axe ${err}`);
		} finally {
			clearTimeout(timeout);
		}
	}

	installErrorCapture();
	window.addEventListener('load', runAxeAudit);
})();
