// Casama page agent (packages/page-agent). Generated: edit the source and run
// `pnpm --filter @casama/page-agent build`. See packages/page-agent/README.md.
(function() {
	// \0virtual:extract-tables
	function extractTables() {
		return (() => {
			const esc = (v) => /[",\n]/.test(v) ? "\"" + v.replace(/"/g, "\"\"") + "\"" : v;
			const cell = (c) => esc(c.innerText.trim().replace(/\s+/g, " "));
			const rows = (t) => [...t.querySelectorAll("tr")].map((tr) => [...tr.querySelectorAll("th,td")].map(cell).join(","));
			const tables = [...document.querySelectorAll("table")].filter((t) => t.offsetParent !== null);
			if (tables.length) return tables.slice(0, 5).map((t, i) => "# Table " + (i + 1) + "\n" + rows(t).join("\n")).join("\n\n");
			return [...document.querySelectorAll("ul,ol")].filter((l) => l.offsetParent !== null && l.children.length >= 3).slice(0, 3).map((l, i) => "# List " + (i + 1) + "\n" + [...l.children].map(cell).join("\n")).join("\n\n") || "No tables or lists on this page.";
		})();
	}
	// src/prims.ts
	/**
	* Built-ins the page agent relies on, captured when the script starts. It runs at document start,
	* before any page script, so these are the browser's own. A page that later replaces
	* `String.prototype.trim`, `Element.prototype.getAttribute`, `JSON.stringify` or an array index
	* setter can't change what the agent reads or does.
	*
	* Rules for the rest of the source: no method calls on strings, arrays or DOM objects (use the
	* captured functions here), no regular expressions, no `for…of` or spread over arrays (iterators
	* can be replaced), and growing arrays come from `list()` (no prototype, so no inherited setters).
	* Object and array literals are fine: they define their properties without running setters.
	*/
	var FnProto = Function.prototype;
	var O = Object;
	/** `f.call(self, ...a)` that keeps working after the page swaps `Function.prototype.call`. */
	var uncurry = FnProto.bind.bind(FnProto.call);
	var getOwnDesc = O.getOwnPropertyDescriptor;
	var getProto = O.getPrototypeOf;
	var setProto = O.setPrototypeOf;
	var defineProp = O.defineProperty;
	var freeze = O.freeze;
	var create = O.create;
	var objectKeys = O.keys;
	function lookup(o, k) {
		let p = o;
		for (let i = 0; p && i < 20; i++) {
			const d = getOwnDesc(p, k);
			if (d) return d;
			p = getProto(p);
		}
	}
	/** A property getter of [o] (or its prototypes), callable on any instance. */
	function getter(o, k) {
		const g = o ? lookup(o, k)?.get : void 0;
		if (!g) return () => void 0;
		return uncurry(g);
	}
	/** A property setter of [o] (or its prototypes), callable on any instance. */
	function setter(o, k) {
		const s = o ? lookup(o, k)?.set : void 0;
		if (!s) return () => {};
		return uncurry(s);
	}
	function method(o, k) {
		const f = (o ? lookup(o, k) : void 0)?.value;
		return typeof f === "function" ? uncurry(f) : void 0;
	}
	function must(o, k) {
		return method(o, k) ?? (() => void 0);
	}
	var W = globalThis;
	var WIN = W;
	var DOC = W.document;
	W.top;
	var PARENT = W.parent;
	var IS_TOP = W.top === W;
	var LOC = W.location;
	var SP = String.prototype;
	var strSlice = must(SP, "slice");
	var strIndexOf = must(SP, "indexOf");
	var strLower = must(SP, "toLowerCase");
	must(SP, "toUpperCase");
	var strTrim = must(SP, "trim");
	var strCode = must(SP, "charCodeAt");
	var fromCharCode = String.fromCharCode;
	var toStr = String;
	var num = Number;
	var parseNum = W.parseFloat;
	var isNaNum = Number.isNaN;
	var arrJoin = must(Array.prototype, "join");
	var isArray = Array.isArray;
	var mathMin = Math.min;
	var mathMax = Math.max;
	var mathImul = Math.imul;
	var jsonStringify = JSON.stringify;
	var jsonParse = JSON.parse;
	var PromiseCtor = Promise;
	var WeakRefCtor = W.WeakRef;
	var weakDeref = must(W.WeakRef?.prototype, "deref");
	var WeakMapCtor = WeakMap;
	var weakMapGet = must(WeakMap.prototype, "get");
	var weakMapSet = must(WeakMap.prototype, "set");
	var Uint8 = Uint8Array;
	var u8Subarray = must(Uint8Array.prototype, "subarray");
	var u8Set = must(Uint8Array.prototype, "set");
	var btoaFn = W.btoa;
	var atobFn = W.atob;
	var setTimeoutFn = W.setTimeout;
	W.clearTimeout;
	var fetchFn = W.fetch;
	W.crypto && must(W.crypto, "getRandomValues");
	W.crypto;
	var URLCtor = W.URL;
	var urlHref = getter(W.URL?.prototype, "href");
	var urlPathname = getter(W.URL?.prototype, "pathname");
	var urlProtocol = getter(W.URL?.prototype, "protocol");
	var getComputedStyleFn = must(W, "getComputedStyle");
	var styleValue = must(W.CSSStyleDeclaration?.prototype, "getPropertyValue");
	var winPostMessage = must(W, "postMessage");
	var scrollX = getter(W, "scrollX");
	var scrollY = getter(W, "scrollY");
	var innerWidth = getter(W, "innerWidth");
	var innerHeight = getter(W, "innerHeight");
	var winScrollBy = must(W, "scrollBy");
	var locHref = getter(LOC, "href");
	var locHost = getter(LOC, "host");
	getter(LOC, "origin");
	var LOCATION = LOC;
	var winGetSelection = must(W, "getSelection");
	var NP = W.Node.prototype;
	var EP = W.Element.prototype;
	var HP = W.HTMLElement.prototype;
	var parentNode = getter(NP, "parentNode");
	var firstChild = getter(NP, "firstChild");
	var nextSibling = getter(NP, "nextSibling");
	var nodeType = getter(NP, "nodeType");
	var nodeValue = getter(NP, "nodeValue");
	getter(NP, "textContent");
	var setTextContent = setter(NP, "textContent");
	var ownerDocument = getter(NP, "ownerDocument");
	var isConnected = getter(NP, "isConnected");
	var nodeContains = must(NP, "contains");
	var getRootNode = must(NP, "getRootNode");
	var localName = getter(EP, "localName");
	var shadowRoot = getter(EP, "shadowRoot");
	var getAttribute = must(EP, "getAttribute");
	var hasAttribute = must(EP, "hasAttribute");
	var getRect = must(EP, "getBoundingClientRect");
	var closest = must(EP, "closest");
	var matches = must(EP, "matches");
	must(EP, "querySelector");
	var scrollIntoView = must(EP, "scrollIntoView");
	var scrollIntoViewIfNeeded = method(EP, "scrollIntoViewIfNeeded");
	var elScrollBy = must(EP, "scrollBy");
	var scrollTop = getter(EP, "scrollTop");
	var scrollLeft = getter(EP, "scrollLeft");
	var scrollHeight = getter(EP, "scrollHeight");
	var scrollWidth = getter(EP, "scrollWidth");
	var clientHeight = getter(EP, "clientHeight");
	var clientWidth = getter(EP, "clientWidth");
	var clientLeft = getter(EP, "clientLeft");
	var clientTop = getter(EP, "clientTop");
	var focusEl = must(HP, "focus");
	var isContentEditable = getter(HP, "isContentEditable");
	var shadowHost = getter(W.ShadowRoot?.prototype, "host");
	var rootActiveElement = getter(W.ShadowRoot?.prototype, "activeElement");
	var rootElementFromPoint = must(W.ShadowRoot?.prototype, "elementFromPoint");
	var fragGetElementById = must(W.DocumentFragment?.prototype, "getElementById");
	var assignedNodes = must(W.HTMLSlotElement?.prototype, "assignedNodes");
	var IP = W.HTMLInputElement.prototype;
	var TP = W.HTMLTextAreaElement.prototype;
	var SLP = W.HTMLSelectElement.prototype;
	var OP = W.HTMLOptionElement.prototype;
	var inputValue = getter(IP, "value");
	var setInputValue = setter(IP, "value");
	var inputChecked = getter(IP, "checked");
	var inputIndeterminate = getter(IP, "indeterminate");
	var inputSelect = must(IP, "select");
	var setInputFiles = setter(IP, "files");
	var inputReadOnly = getter(IP, "readOnly");
	var textareaValue = getter(TP, "value");
	var setTextareaValue = setter(TP, "value");
	var textareaSelect = must(TP, "select");
	var textareaReadOnly = getter(TP, "readOnly");
	var selectOptions = getter(SLP, "options");
	var selectSelectedIndex = getter(SLP, "selectedIndex");
	var setSelectSelectedIndex = setter(SLP, "selectedIndex");
	var selectMultiple = getter(SLP, "multiple");
	var selectSize = getter(SLP, "size");
	var optionText = getter(OP, "text");
	var optionValue = getter(OP, "value");
	var optionSelected = getter(OP, "selected");
	var collectionLength = getter(W.HTMLCollection?.prototype, "length");
	var collectionItem = must(W.HTMLCollection?.prototype, "item");
	var nodeListLength = getter(W.NodeList?.prototype, "length");
	var nodeListItem = must(W.NodeList?.prototype, "item");
	/** `el.form` for whichever form-associated element [el] is. */
	var formGetters = [
		getter(IP, "form"),
		getter(TP, "form"),
		getter(SLP, "form"),
		getter(W.HTMLButtonElement.prototype, "form")
	];
	var labelsGetters = [
		getter(IP, "labels"),
		getter(TP, "labels"),
		getter(SLP, "labels"),
		getter(W.HTMLButtonElement.prototype, "labels")
	];
	var FORM_TAGS = [
		"input",
		"textarea",
		"select",
		"button"
	];
	function formOf(el) {
		const tag = localName(el);
		for (let i = 0; i < FORM_TAGS.length; i++) if (FORM_TAGS[i] === tag) return formGetters[i](el);
		return closest(el, "form");
	}
	function labelsOf(el) {
		const tag = localName(el);
		for (let i = 0; i < FORM_TAGS.length; i++) if (FORM_TAGS[i] === tag) return labelsGetters[i](el);
		return null;
	}
	getter(W.HTMLLabelElement?.prototype, "control");
	var formQuerySelector = must(W.HTMLFormElement.prototype, "querySelector");
	var formRequestSubmit = method(W.HTMLFormElement.prototype, "requestSubmit");
	var iframeContentWindow = getter(W.HTMLIFrameElement.prototype, "contentWindow");
	var frameContentWindow = getter(W.HTMLFrameElement?.prototype, "contentWindow");
	var DP = W.Document.prototype;
	var docActiveElement = getter(DP, "activeElement");
	var docElementFromPoint = must(DP, "elementFromPoint");
	var docGetElementById = must(DP, "getElementById");
	var docCreateRange = must(DP, "createRange");
	var docExecCommand = must(DP, "execCommand");
	var docTitle = getter(DP, "title");
	var docElement = getter(DP, "documentElement");
	var docBody = getter(DP, "body");
	getter(DP, "scrollingElement");
	var docQuerySelectorAll = must(DP, "querySelectorAll");
	var rangeSelectNodeContents = must(W.Range.prototype, "selectNodeContents");
	var rangeRect = must(W.Range.prototype, "getBoundingClientRect");
	must(W.Range.prototype, "collapse");
	var selRemoveAllRanges = must(W.Selection?.prototype, "removeAllRanges");
	var selAddRange = must(W.Selection?.prototype, "addRange");
	var RP = W.DOMRect?.prototype ?? W.DOMRectReadOnly?.prototype;
	var rectLeft = getter(RP, "left");
	var rectTop = getter(RP, "top");
	var rectWidth = getter(RP, "width");
	var rectHeight = getter(RP, "height");
	var ETP = W.EventTarget.prototype;
	var addListener = must(ETP, "addEventListener");
	var dispatch = must(ETP, "dispatchEvent");
	var EventCtor = W.Event;
	var MouseEventCtor = W.MouseEvent;
	var PointerEventCtor = W.PointerEvent ?? W.MouseEvent;
	var KeyboardEventCtor = W.KeyboardEvent;
	var InputEventCtor = W.InputEvent ?? W.Event;
	W.FocusEvent ?? W.Event;
	var MessageChannelCtor = W.MessageChannel;
	getter(W.Event.prototype, "defaultPrevented");
	var stopImmediate = must(W.Event.prototype, "stopImmediatePropagation");
	var messageData = getter(W.MessageEvent.prototype, "data");
	var messageSource = getter(W.MessageEvent.prototype, "source");
	var messagePorts = getter(W.MessageEvent.prototype, "ports");
	var portPostMessage = must(W.MessagePort.prototype, "postMessage");
	var portStart = must(W.MessagePort.prototype, "start");
	var portClose = must(W.MessagePort.prototype, "close");
	var channelPort1 = getter(W.MessageChannel?.prototype, "port1");
	var channelPort2 = getter(W.MessageChannel?.prototype, "port2");
	var DataTransferCtor = W.DataTransfer;
	var FileCtor = W.File;
	var dataTransferItems = getter(W.DataTransfer?.prototype, "items");
	var dataTransferFiles = getter(W.DataTransfer?.prototype, "files");
	var itemsAdd = must(W.DataTransferItemList?.prototype, "add");
	var responseOk = getter(W.Response?.prototype, "ok");
	var responseStatus = getter(W.Response?.prototype, "status");
	var responseUrl = getter(W.Response?.prototype, "url");
	var responseHeaders = getter(W.Response?.prototype, "headers");
	var responseBody = getter(W.Response?.prototype, "body");
	must(W.Response?.prototype, "arrayBuffer");
	var headersGet = must(W.Headers?.prototype, "get");
	var streamGetReader = must(W.ReadableStream?.prototype, "getReader");
	var readerRead = must(W.ReadableStreamDefaultReader?.prototype, "read");
	var readerCancel = must(W.ReadableStreamDefaultReader?.prototype, "cancel");
	/** An array with no prototype: index writes can't reach a setter the page put on Array.prototype. */
	function list() {
		return setProto([], null);
	}
	function push(a, v) {
		a[a.length] = v;
	}
	function join(a, sep) {
		return arrJoin(a, sep);
	}
	/** A plain record with no prototype. */
	function record() {
		return create(null);
	}
	var isSpace = (c) => c === 32 || c === 9 || c === 10 || c === 13 || c === 12 || c === 160 || c === 8203;
	/** Whitespace collapsed to single spaces, trimmed, cut to [max] with an ellipsis. */
	function clean(v, max = 150) {
		const s = typeof v === "string" ? v : v == null ? "" : toStr(v);
		let space = false;
		let out = "";
		for (let i = 0; i < s.length; i++) {
			if (isSpace(strCode(s, i))) {
				space = out.length > 0;
				continue;
			}
			if (space) out += " ";
			space = false;
			out += s[i];
			if (out.length > max + 8) break;
		}
		return out.length > max ? `${strSlice(out, 0, max - 1)}…` : out;
	}
	/** Whitespace-separated words of [s]. */
	function words(s) {
		const out = list();
		if (!s) return out;
		let w = "";
		for (let i = 0; i < s.length; i++) if (isSpace(strCode(s, i))) {
			if (w) push(out, w);
			w = "";
		} else w += s[i];
		if (w) push(out, w);
		return out;
	}
	function startsWith(s, p) {
		return strSlice(s, 0, p.length) === p;
	}
	function includes(s, t) {
		return strIndexOf(s, t) !== -1;
	}
	/** `"text"` with inner quotes escaped, as agent-browser prints names. */
	function quote(t) {
		let out = "\"";
		for (let i = 0; i < t.length; i++) out += t[i] === "\"" ? "\\\"" : t[i];
		return `${out}"`;
	}
	var HEX = "0123456789abcdef";
	/** FNV-1a, 32 bits, as 8 hex digits. */
	function hash(s) {
		let h = 2166136261;
		for (let i = 0; i < s.length; i++) {
			h ^= strCode(s, i);
			h = mathImul(h, 16777619);
		}
		let out = "";
		for (let i = 7; i >= 0; i--) out += HEX[h >>> i * 4 & 15];
		return out;
	}
	function sleep(ms) {
		return new PromiseCtor((r) => {
			setTimeoutFn(r, ms);
		});
	}
	function style(el) {
		return getComputedStyleFn(WIN, el);
	}
	function css(s, p) {
		return styleValue(s, p);
	}
	/** Elements whose content is never shown or read. */
	var SKIP_TAGS = {
		script: true,
		style: true,
		template: true,
		head: true,
		noscript: true,
		meta: true,
		link: true,
		title: true
	};
	function isSkipped(el) {
		return SKIP_TAGS[localName(el)] === true;
	}
	/** Children in the flattened tree: a shadow host's shadow root, a slot's assigned nodes. */
	function kids(n) {
		const out = list();
		if (nodeType(n) === 1) {
			const el = n;
			const root = shadowRoot(el);
			if (root) {
				for (let c = firstChild(root); c; c = nextSibling(c)) push(out, c);
				return out;
			}
			if (localName(el) === "slot") {
				const got = assignedNodes(el, { flatten: true });
				if (got?.length) {
					for (let i = 0; i < got.length; i++) push(out, got[i]);
					return out;
				}
			}
		}
		for (let c = firstChild(n); c; c = nextSibling(c)) push(out, c);
		return out;
	}
	/** The parent in the flattened tree: a shadow root's host stands in for the root. */
	function flatParent(n) {
		const p = parentNode(n);
		if (p && nodeType(p) === 11) try {
			return shadowHost(p);
		} catch {
			return null;
		}
		return p;
	}
	var CLIPS = (v) => v === "hidden" || v === "clip";
	/** Whether [el] itself hides what's inside it (its parent is visible). */
	function selfHidden(el) {
		if (hasAttribute(el, "hidden") || hasAttribute(el, "inert")) return true;
		if (getAttribute(el, "aria-hidden") === "true") return true;
		const s = style(el);
		const display = css(s, "display");
		if (display === "none") return true;
		const visibility = css(s, "visibility");
		if (visibility === "hidden" || visibility === "collapse") return true;
		const opacity = css(s, "opacity");
		if (opacity !== "" && parseNum(opacity) < .05) return true;
		if (zeroRect(css(s, "clip"))) return true;
		const clipPath = css(s, "clip-path");
		if (startsWith(clipPath, "inset(50%") || startsWith(clipPath, "inset(100%") || startsWith(clipPath, "circle(0")) return true;
		if (display === "contents") return false;
		const r = getRect(el);
		const w = rectWidth(r);
		const h = rectHeight(r);
		if ((CLIPS(css(s, "overflow-x")) || CLIPS(css(s, "overflow-y"))) && (w <= 1 || h <= 1)) return true;
		const x = rectLeft(r) + scrollX(WIN);
		const y = rectTop(r) + scrollY(WIN);
		if (x + w < 0 || y + h < 0) return true;
		return false;
	}
	/** `rect(0px, 0px, 0px, 0px)` in any spacing. */
	function zeroRect(clip) {
		if (!startsWith(clip, "rect(")) return false;
		let t = "";
		for (let i = 5; i < clip.length; i++) {
			const c = clip[i];
			if (c === " " || c === "," || c === "p" || c === "x" || c === ")") continue;
			t += c;
		}
		return t === "0000";
	}
	/** Whether a text node (in a visible parent) is too small to see. */
	function textHidden(t, parent) {
		if (parent) {
			if (parseNum(css(style(parent), "font-size") || "16") < 2) return true;
		}
		const r = docCreateRange(DOC);
		rangeSelectNodeContents(r, t);
		const box = rangeRect(r);
		return rectWidth(box) < 1 || rectHeight(box) < 1;
	}
	var hiddenMemo = new WeakMapCtor();
	/** Forget cached visibility (each command starts fresh). */
	function resetMemo() {
		hiddenMemo = new WeakMapCtor();
	}
	/** Whether [el] or anything above it (in the flattened tree) hides it. */
	function hiddenUp(el) {
		const got = weakMapGet(hiddenMemo, el);
		if (got !== void 0) return got;
		let h = false;
		const p = flatParent(el);
		if (p && nodeType(p) === 1) h = hiddenUp(p);
		if (!h) h = selfHidden(el);
		weakMapSet(hiddenMemo, el, h);
		return h;
	}
	/** Elements a bot can act on; each gets a ref. */
	var INTERACTIVE = {
		button: true,
		link: true,
		textbox: true,
		searchbox: true,
		combobox: true,
		checkbox: true,
		radio: true,
		switch: true,
		slider: true,
		spinbutton: true,
		menuitem: true,
		menuitemcheckbox: true,
		menuitemradio: true,
		option: true,
		tab: true,
		treeitem: true,
		listbox: true
	};
	/** Shown in a full snapshot besides interactive elements. */
	var CONTENT = {
		heading: true,
		img: true,
		image: true,
		cell: true,
		columnheader: true,
		rowheader: true,
		alert: true,
		status: true
	};
	/** Roles that take their name from what's inside them. */
	var NAME_FROM_CONTENT = {
		button: true,
		link: true,
		checkbox: true,
		radio: true,
		switch: true,
		tab: true,
		menuitem: true,
		menuitemcheckbox: true,
		menuitemradio: true,
		option: true,
		treeitem: true,
		heading: true,
		cell: true,
		columnheader: true,
		rowheader: true,
		alert: true,
		status: true,
		tooltip: true
	};
	var NOT_EDITABLE_INPUTS = {
		checkbox: true,
		radio: true,
		submit: true,
		button: true,
		reset: true,
		image: true,
		file: true,
		hidden: true,
		range: true,
		color: true
	};
	function inputType(el) {
		return strLower(getAttribute(el, "type") ?? "");
	}
	function focusable(el) {
		return matches(el, "a[href],button,input,select,textarea,[tabindex],[contenteditable]");
	}
	/** The element's role: explicit `role` first, else its implicit one. */
	function roleOf(el) {
		const explicit = words(strLower(getAttribute(el, "role") ?? ""));
		if (explicit.length) {
			const r = explicit[0];
			if (!((r === "none" || r === "presentation") && focusable(el))) return r;
		}
		switch (localName(el)) {
			case "a":
			case "area": return hasAttribute(el, "href") ? "link" : "";
			case "button": return "button";
			case "input": {
				const t = inputType(el);
				if (t === "button" || t === "submit" || t === "reset" || t === "image" || t === "file") return "button";
				if (t === "checkbox") return "checkbox";
				if (t === "radio") return "radio";
				if (t === "range") return "slider";
				if (t === "number") return "spinbutton";
				if (t === "hidden" || t === "color") return "";
				if (t === "search") return hasAttribute(el, "list") ? "combobox" : "searchbox";
				return hasAttribute(el, "list") ? "combobox" : "textbox";
			}
			case "textarea": return "textbox";
			case "select": return selectMultiple(el) || selectSize(el) > 1 ? "listbox" : "combobox";
			case "option": return "option";
			case "summary": return "button";
			case "h1":
			case "h2":
			case "h3":
			case "h4":
			case "h5":
			case "h6": return "heading";
			case "img": return getAttribute(el, "alt") === "" ? "presentation" : "img";
			case "td": return "cell";
			case "th": return getAttribute(el, "scope") === "row" ? "rowheader" : "columnheader";
			case "output": return "status";
			case "p": return "paragraph";
			case "li": return "listitem";
			case "tr": return "row";
			case "blockquote": return "blockquote";
			case "article": return "article";
			case "section": return "section";
			case "main": return "main";
		}
		if (isContentEditable(el)) {
			const p = parentNode(el);
			if (!p || nodeType(p) !== 1 || !isContentEditable(p)) return "textbox";
		}
		return "";
	}
	/** Text a person can see inside [n], with images' alt text; form controls are skipped. */
	function visibleText(n, max = 400) {
		const out = list();
		let size = 0;
		const walk = (node, depth) => {
			if (size > max || depth > 60) return;
			const cs = kids(node);
			for (let i = 0; i < cs.length; i++) {
				const c = cs[i];
				const t = nodeType(c);
				if (t === 3) {
					const v = nodeValue(c) ?? "";
					if (!strTrim(v)) continue;
					if (textHidden(c, node)) continue;
					push(out, v);
					size += v.length;
				} else if (t === 1) {
					const el = c;
					if (isSkipped(el) || selfHidden(el)) continue;
					const tag = localName(el);
					if (tag === "input" || tag === "select" || tag === "textarea" || tag === "iframe") continue;
					if (tag === "img") {
						const alt = getAttribute(el, "alt");
						if (alt) push(out, ` ${alt} `);
						continue;
					}
					const block = isBlock(el);
					if (block) push(out, " ");
					walk(el, depth + 1);
					if (block) push(out, " ");
				}
			}
		};
		walk(n, 0);
		return clean(join(out, ""), max);
	}
	function isBlock(el) {
		const d = css(style(el), "display");
		return !(d === "inline" || d === "contents" || d === "" || startsWith(d, "inline"));
	}
	function byId(el, id) {
		const root = getRootNode(el);
		if (root && nodeType(root) === 11) return fragGetElementById(root, id);
		return docGetElementById(DOC, id);
	}
	/** The element's accessible name, from visible text and labelling attributes. */
	function nameOf(el, role) {
		const ids = words(getAttribute(el, "aria-labelledby"));
		if (ids.length) {
			const parts = list();
			for (let i = 0; i < ids.length; i++) {
				const target = byId(el, ids[i]);
				if (target && !hiddenUp(target)) push(parts, visibleText(target));
			}
			const t = clean(join(parts, " "));
			if (t) return t;
		}
		const label = clean(getAttribute(el, "aria-label"));
		if (label) return label;
		const labels = labelsOf(el);
		if (labels) {
			const parts = list();
			const n = nodeListLength(labels);
			for (let i = 0; i < n; i++) {
				const l = nodeListItem(labels, i);
				if (l && !hiddenUp(l)) push(parts, visibleText(l));
			}
			const t = clean(join(parts, " "));
			if (t) return t;
		}
		const tag = localName(el);
		if (tag === "img" || tag === "area" || tag === "input" && inputType(el) === "image") {
			const alt = clean(getAttribute(el, "alt"));
			if (alt) return alt;
		}
		if (tag === "input") {
			const t = inputType(el);
			if (t === "submit" || t === "button" || t === "reset") {
				const v = clean(getAttribute(el, "value"));
				if (v) return v;
				if (t === "submit") return "Submit";
				if (t === "reset") return "Reset";
			}
		}
		if (NAME_FROM_CONTENT[role] === true) {
			const t = visibleText(el, 150);
			if (t) return t;
		}
		const title = clean(getAttribute(el, "title"));
		if (title) return title;
		const ph = clean(getAttribute(el, "placeholder") ?? getAttribute(el, "aria-placeholder"));
		if (ph) return ph;
		return "";
	}
	/**
	* Fields whose contents belong to the person: passwords, cards and one-time codes. Their values
	* are never read, and `fill` and `type` refuse them.
	*/
	function isSensitive(el) {
		if (localName(el) === "input" && inputType(el) === "password") return true;
		const tokens = words(strLower(getAttribute(el, "autocomplete") ?? ""));
		for (let i = 0; i < tokens.length; i++) {
			const t = tokens[i];
			if (t === "one-time-code" || t === "current-password" || t === "new-password") return true;
			if (startsWith(t, "cc-")) return true;
		}
		return false;
	}
	/** A text field or an editable area. */
	function isEditable(el) {
		const tag = localName(el);
		if (tag === "textarea") return true;
		if (tag === "input") return NOT_EDITABLE_INPUTS[inputType(el)] !== true;
		return isContentEditable(el);
	}
	function isReadOnly(el) {
		const tag = localName(el);
		if (tag === "input") return inputReadOnly(el);
		if (tag === "textarea") return textareaReadOnly(el);
		return false;
	}
	function isDisabled(el) {
		if (getAttribute(el, "aria-disabled") === "true") return true;
		const tag = localName(el);
		if (tag === "input" || tag === "button" || tag === "select" || tag === "textarea" || tag === "option" || tag === "fieldset") return matches(el, ":disabled");
		return false;
	}
	/** What a field shows, for the snapshot. Never read for sensitive fields. */
	function shownValue(el, role) {
		if (isSensitive(el)) return "";
		const tag = localName(el);
		if (tag === "select") {
			const i = selectSelectedIndex(el);
			if (i < 0) return "";
			const o = collectionItem(selectOptions(el), i);
			return o ? optionText(o) : "";
		}
		if (tag === "input" || tag === "textarea") return readValue(el);
		if (role === "textbox" && isContentEditable(el)) return visibleText(el, 200);
		return getAttribute(el, "aria-valuetext") ?? getAttribute(el, "aria-valuenow") ?? "";
	}
	/** The value of an input or textarea. The only place values are read; callers check isSensitive. */
	function readValue(el) {
		if (isSensitive(el)) return "";
		return localName(el) === "textarea" ? textareaValue(el) : inputValue(el);
	}
	/** The flags agent-browser prints after an element. */
	function flagsOf(el, role, focused) {
		const out = list();
		const tag = localName(el);
		let checked = null;
		if (tag === "input" && (role === "checkbox" || role === "radio")) {
			if (inputIndeterminate(el)) checked = "mixed";
			else if (inputChecked(el)) checked = "true";
		} else checked = getAttribute(el, "aria-checked");
		if (checked === "true") push(out, "[checked]");
		if (checked === "mixed") push(out, "[mixed]");
		if (isDisabled(el)) push(out, "[disabled]");
		let expanded = getAttribute(el, "aria-expanded");
		if (expanded === null && tag === "summary") {
			const details = parentNode(el);
			if (details && nodeType(details) === 1 && localName(details) === "details") expanded = hasAttribute(details, "open") ? "true" : "false";
		}
		if (expanded === "true") push(out, "[expanded]");
		if (expanded === "false") push(out, "[collapsed]");
		if (tag === "option" ? optionSelected(el) : getAttribute(el, "aria-selected") === "true") push(out, "[selected]");
		if (focused && focused === el) push(out, "[focused]");
		if (role === "heading") {
			const lvl = headingLevel(el);
			if (lvl) push(out, `[level=${lvl}]`);
		}
		return out.length ? ` ${join(out, " ")}` : "";
	}
	function headingLevel(el) {
		const aria = parseNum(getAttribute(el, "aria-level") ?? "");
		if (aria >= 1) return aria - aria % 1;
		const tag = localName(el);
		if (tag.length === 2 && tag[0] === "h") {
			const n = parseNum(strSlice(tag, 1));
			if (n >= 1 && n <= 6) return n;
		}
		return 2;
	}
	/** The focused element, looking inside open shadow roots. Frames are the caller's business. */
	function focusedHere() {
		let el = docActiveElement(DOC);
		for (let i = 0; i < 30 && el; i++) {
			const root = shadowRoot(el);
			if (!root) break;
			const inner = rootActiveElement(root);
			if (!inner) break;
			el = inner;
		}
		if (!el) return {
			el: null,
			closedShadow: false
		};
		const tag = localName(el);
		if (tag === "body" || tag === "html") return {
			el: null,
			closedShadow: false
		};
		const closedShadow = includes(tag, "-") && !shadowRoot(el) && !hasAttribute(el, "tabindex") && !isContentEditable(el);
		return {
			el,
			closedShadow
		};
	}
	var SUBMIT_SEL = "button:not([type=\"button\"]):not([type=\"reset\"]), input[type=\"submit\"], input[type=\"image\"]";
	/** What packages/domain/src/browser-risk.ts needs to know about an element. Nothing from values. */
	function factsOf(el) {
		const tag = localName(el);
		const type = tag === "input" || tag === "button" ? inputType(el) : "";
		const form = formOf(el);
		const submits = !!form && (tag === "button" && type !== "button" && type !== "reset" || tag === "input" && (type === "submit" || type === "image"));
		const passwordForm = !!form && !!formQuerySelector(form, "input[type=\"password\"]");
		const btn = form ? formQuerySelector(form, SUBMIT_SEL) : null;
		const role = roleOf(el);
		return {
			role,
			name: nameOf(el, role),
			url: locHref(LOCATION),
			tag,
			inputType: type,
			autocomplete: strLower(getAttribute(el, "autocomplete") ?? ""),
			submits,
			passwordForm,
			inForm: !!form,
			submitName: btn ? clean(nameOf(btn, roleOf(btn)), 100) : "",
			editable: isEditable(el),
			isFile: tag === "input" && type === "file",
			host: locHost(LOCATION)
		};
	}
	function fingerprintOf(f) {
		return hash(`${f.role}|${f.name}|${f.tag}|${f.inputType}|${f.autocomplete}|${f.submits}|${f.passwordForm}|${f.host}`);
	}
	/** The label element [hit] sits in, when it labels [el]. */
	function labelFor(hit, el) {
		const l = closest(hit, "label");
		if (!l) return false;
		const labels = labelsOf(el);
		if (!labels) return false;
		const n = nodeListLength(labels);
		for (let i = 0; i < n; i++) if (nodeListItem(labels, i) === l) return true;
		return false;
	}
	// \0@oxc-project+runtime@0.156.0/helpers/esm/typeof.js
	function _typeof(o) {
		"@babel/helpers - typeof";
		return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function(o) {
			return typeof o;
		} : function(o) {
			return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o;
		}, _typeof(o);
	}
	// \0@oxc-project+runtime@0.156.0/helpers/esm/toPrimitive.js
	function toPrimitive(t, r) {
		if ("object" != _typeof(t) || !t) return t;
		var e = t[Symbol.toPrimitive];
		if (void 0 !== e) {
			var i = e.call(t, r || "default");
			if ("object" != _typeof(i)) return i;
			throw new TypeError("@@toPrimitive must return a primitive value.");
		}
		return ("string" === r ? String : Number)(t);
	}
	// \0@oxc-project+runtime@0.156.0/helpers/esm/toPropertyKey.js
	function toPropertyKey(t) {
		var i = toPrimitive(t, "string");
		return "symbol" == _typeof(i) ? i : i + "";
	}
	// \0@oxc-project+runtime@0.156.0/helpers/esm/defineProperty.js
	function _defineProperty(e, r, t) {
		return (r = toPropertyKey(r)) in e ? Object.defineProperty(e, r, {
			value: t,
			enumerable: !0,
			configurable: !0,
			writable: !0
		}) : e[r] = t, e;
	}
	// src/act.ts
	/**
	* Steps on one element of this frame: the covered check, clicks, filling and typing through the
	* browser's own editing path, keys, scrolling, upload fields and downloads.
	*/
	/** Marks the agent's own errors (checked by identity, not instanceof, which a page can hook). */
	var FAIL = {};
	var Fail = class {
		constructor(code, message) {
			_defineProperty(this, "code", void 0);
			_defineProperty(this, "message", void 0);
			_defineProperty(this, "brand", FAIL);
			this.code = code;
			this.message = message;
		}
	};
	function isFail(e) {
		return typeof e === "object" && e !== null && e.brand === FAIL;
	}
	var reflectApply$1 = Reflect.apply;
	var decodeUri = decodeURIComponent;
	/** Brings [el] into view if it isn't. */
	function reveal(el) {
		const r = getRect(el);
		if (rectTop(r) >= 0 && rectLeft(r) >= 0 && rectTop(r) + rectHeight(r) <= innerHeight(WIN) && rectLeft(r) + rectWidth(r) <= innerWidth(WIN)) return;
		if (scrollIntoViewIfNeeded) scrollIntoViewIfNeeded(el, true);
		else scrollIntoView(el, {
			block: "center",
			inline: "center"
		});
	}
	/** The centre of the part of [el] inside the viewport. */
	function centerOf(el) {
		const r = getRect(el);
		if (rectWidth(r) < 1 || rectHeight(r) < 1) throw new Fail("covered", "That element isn't visible on the page. Take a new snapshot.");
		const left = mathMax(rectLeft(r), 0);
		const top = mathMax(rectTop(r), 0);
		const right = mathMin(rectLeft(r) + rectWidth(r), innerWidth(WIN));
		const bottom = mathMin(rectTop(r) + rectHeight(r), innerHeight(WIN));
		if (right - left < 1 || bottom - top < 1) throw new Fail("covered", "That element is off the screen and couldn't be scrolled to.");
		return {
			x: (left + right) / 2,
			y: (top + bottom) / 2
		};
	}
	function isShadowRoot(n) {
		return nodeType(n) === 11;
	}
	/** What's at (x, y), as seen from [el]'s own tree (document or shadow root). */
	function hitAt(el, x, y) {
		const root = getRootNode(el);
		if (isShadowRoot(root)) return rootElementFromPoint(root, x, y);
		return docElementFromPoint(DOC, x, y);
	}
	/** Whether [el] is what's under (x, y): nothing covers it. Returns the element hit when it is. */
	function onTop(el, x, y) {
		const hit = hitAt(el, x, y);
		if (!hit) return null;
		if (hit === el || nodeContains(el, hit)) return hit;
		let h = hit;
		for (let i = 0; h && i < 30; i++) {
			const root = getRootNode(h);
			if (!isShadowRoot(root)) break;
			h = shadowHost(root);
			if (h === el || h && nodeContains(el, h)) return hit;
		}
		return labelFor(hit, el) ? hit : null;
	}
	/** Scrolls [el] into view and checks nothing covers its centre. */
	function locate(el) {
		reveal(el);
		const { x, y } = centerOf(el);
		const hit = onTop(el, x, y);
		if (!hit) throw new Fail("covered", "Something else on the page covers that element, so it wasn't touched. Take a new snapshot.");
		return {
			x,
			y,
			hit
		};
	}
	var FOCUSABLE = "a[href],area[href],button,input:not([type=\"hidden\"]),select,textarea,summary,iframe,[tabindex],[contenteditable]:not([contenteditable=\"false\"])";
	function mouseInit(x, y, buttons, detail) {
		return {
			bubbles: true,
			cancelable: true,
			composed: true,
			view: WIN,
			clientX: x,
			clientY: y,
			screenX: x,
			screenY: y,
			button: 0,
			buttons,
			detail
		};
	}
	function pointer(type, target, x, y, buttons) {
		return dispatch(target, new PointerEventCtor(type, {
			...mouseInit(x, y, buttons, 0),
			pointerId: 1,
			pointerType: "mouse",
			isPrimary: true,
			width: 1,
			height: 1,
			pressure: buttons ? .5 : 0
		}));
	}
	function mouse(type, target, x, y, buttons) {
		return dispatch(target, new MouseEventCtor(type, mouseInit(x, y, buttons, type === "click" ? 1 : 0)));
	}
	/** The events of a mouse click at (x, y) on [target], with focus moving like a real click. */
	function clickAt(target, x, y) {
		pointer("pointerover", target, x, y, 0);
		mouse("mouseover", target, x, y, 0);
		const downOk = pointer("pointerdown", target, x, y, 1);
		const mouseOk = downOk ? mouse("mousedown", target, x, y, 1) : true;
		if (downOk && mouseOk) {
			const f = closest(target, FOCUSABLE);
			if (f) focusEl(f, { preventScroll: true });
		}
		pointer("pointerup", target, x, y, 0);
		if (downOk) mouse("mouseup", target, x, y, 0);
		mouse("click", target, x, y, 0);
	}
	function selectAll(el) {
		const tag = localName(el);
		if (tag === "input") inputSelect(el);
		else if (tag === "textarea") textareaSelect(el);
		else {
			const sel = winGetSelection(WIN);
			if (!sel) return;
			const r = docCreateRange(DOC);
			rangeSelectNodeContents(r, el);
			selRemoveAllRanges(sel);
			selAddRange(sel, r);
		}
	}
	function fire(el, type, data) {
		if (type === "input") dispatch(el, new InputEventCtor("input", {
			bubbles: true,
			composed: true,
			inputType: data ? "insertText" : "deleteContentBackward",
			data: data ?? null
		}));
		else dispatch(el, new EventCtor(type, { bubbles: true }));
	}
	/** The element's text or value, for checking an edit took. Never called on sensitive fields. */
	function contentOf(el) {
		const tag = localName(el);
		if (tag === "input" || tag === "textarea") return readValue(el);
		return visibleText(el, 1e5);
	}
	function setNativeValue(el, v) {
		if (localName(el) === "textarea") setTextareaValue(el, v);
		else setInputValue(el, v);
	}
	function exec(cmd, value) {
		try {
			return docExecCommand(DOC, cmd, false, value);
		} catch {
			return false;
		}
	}
	/** Refuses fields a bot never types into. */
	function guardField(el) {
		if (isSensitive(el)) throw new Fail("unsupported", "That's a password, card or code field: it's typed by the person, not by a bot.");
	}
	function pickOption(el, text) {
		const opts = selectOptions(el);
		const n = collectionLength(opts);
		const want = strLower(strTrim(text));
		for (let pass = 0; pass < 2; pass++) for (let i = 0; i < n; i++) {
			const o = collectionItem(opts, i);
			if (!o) continue;
			const label = strLower(clean(optionText(o)));
			const value = strLower(optionValue(o));
			if (pass === 0 ? label === want || value === want : includes(label, want)) {
				setSelectSelectedIndex(el, i);
				fire(el, "input");
				fire(el, "change");
				return clean(optionText(o));
			}
		}
		throw new Fail("not_editable", `That list has no option "${clean(text, 80)}".`);
	}
	/** Replaces what's in a field with [text] (an empty string clears it). */
	function fill(el, text) {
		const tag = localName(el);
		if (tag === "select") {
			if (isDisabled(el)) throw new Fail("not_editable", "That list is turned off.");
			return `Picked "${pickOption(el, text)}".`;
		}
		if (!isEditable(el)) throw new Fail("not_editable", "That element isn't a text field. Use click for buttons and boxes.");
		guardField(el);
		if (isDisabled(el) || isReadOnly(el)) throw new Fail("not_editable", "That field is read-only or turned off.");
		reveal(el);
		focusEl(el, { preventScroll: true });
		selectAll(el);
		const before = contentOf(el);
		const ok = text ? exec("insertText", text) : exec("delete");
		const after = contentOf(el);
		if (!(text ? ok && after !== before : after === "")) {
			if (tag === "input" || tag === "textarea") {
				setNativeValue(el, text);
				fire(el, "input", text);
			} else {
				setTextContent(el, text);
				fire(el, "input", text);
			}
		}
		if (tag === "input" || tag === "textarea") fire(el, "change");
		const now = contentOf(el);
		return now === text || tag !== "input" ? "" : ` It now shows "${clean(now, 80)}".`;
	}
	/** Inserts [text] where the caret is in the focused field. */
	function typeInto(el, text) {
		if (!isEditable(el)) throw new Fail("not_editable", "Nothing that takes text has focus. Click or fill a field first.");
		guardField(el);
		if (isDisabled(el) || isReadOnly(el)) throw new Fail("not_editable", "That field is read-only or turned off.");
		if (exec("insertText", text)) return;
		const tag = localName(el);
		if (tag !== "input" && tag !== "textarea") throw new Fail("unsupported", "The page didn't take the typed text.");
		setNativeValue(el, readValue(el) + text);
		fire(el, "input", text);
	}
	var KEYS = {
		Enter: {
			code: "Enter",
			keyCode: 13
		},
		Tab: {
			code: "Tab",
			keyCode: 9
		},
		Escape: {
			code: "Escape",
			keyCode: 27
		},
		Backspace: {
			code: "Backspace",
			keyCode: 8
		},
		Delete: {
			code: "Delete",
			keyCode: 46
		},
		" ": {
			code: "Space",
			keyCode: 32
		},
		ArrowUp: {
			code: "ArrowUp",
			keyCode: 38
		},
		ArrowDown: {
			code: "ArrowDown",
			keyCode: 40
		},
		ArrowLeft: {
			code: "ArrowLeft",
			keyCode: 37
		},
		ArrowRight: {
			code: "ArrowRight",
			keyCode: 39
		},
		PageUp: {
			code: "PageUp",
			keyCode: 33
		},
		PageDown: {
			code: "PageDown",
			keyCode: 34
		},
		Home: {
			code: "Home",
			keyCode: 36
		},
		End: {
			code: "End",
			keyCode: 35
		}
	};
	function parseCombo(combo) {
		const parts = list();
		let cur = "";
		for (let i = 0; i < combo.length; i++) if (combo[i] === "+" && cur) {
			push(parts, cur);
			cur = "";
		} else cur += combo[i];
		push(parts, cur);
		let key = parts[parts.length - 1] || combo;
		const c = {
			key,
			code: "",
			keyCode: 0,
			ctrl: false,
			alt: false,
			shift: false,
			meta: false
		};
		for (let i = 0; i < parts.length - 1; i++) {
			const m = strLower(parts[i]);
			if (m === "control" || m === "ctrl") c.ctrl = true;
			else if (m === "alt" || m === "option") c.alt = true;
			else if (m === "shift") c.shift = true;
			else if (m === "meta" || m === "cmd" || m === "command") c.meta = true;
		}
		if (key === "Space" || key === "Spacebar") key = " ";
		if (key === "Esc") key = "Escape";
		if (key === "Return") key = "Enter";
		c.key = key;
		const known = KEYS[key];
		if (known) {
			c.code = known.code;
			c.keyCode = known.keyCode;
		} else if (key.length === 1) {
			const up = key >= "a" && key <= "z" ? fromCharCode(strCode(key, 0) - 32) : key;
			c.code = up >= "A" && up <= "Z" ? `Key${up}` : up >= "0" && up <= "9" ? `Digit${up}` : "";
			c.keyCode = strCode(up, 0);
		} else c.code = key;
		return c;
	}
	function keyEvent(type, target, c) {
		const printable = c.key.length === 1;
		const ev = new KeyboardEventCtor(type, {
			key: c.key,
			code: c.code,
			bubbles: true,
			cancelable: true,
			composed: true,
			view: WIN,
			ctrlKey: c.ctrl,
			altKey: c.alt,
			shiftKey: c.shift,
			metaKey: c.meta
		});
		const kc = type === "keypress" ? printable ? strCode(c.key, 0) : c.keyCode : c.keyCode;
		try {
			defineProp(ev, "keyCode", { get: () => kc });
			defineProp(ev, "which", { get: () => kc });
			if (type === "keypress") defineProp(ev, "charCode", { get: () => kc });
		} catch {}
		return dispatch(target, ev);
	}
	function tabOrder() {
		const all = docQuerySelectorAll(DOC, FOCUSABLE);
		const out = list();
		const n = nodeListLength(all);
		for (let i = 0; i < n; i++) {
			const el = nodeListItem(all, i);
			if (matches(el, "[tabindex=\"-1\"]") || isDisabled(el) || hiddenUp(el)) continue;
			push(out, el);
		}
		return out;
	}
	function moveFocus(from, back) {
		const order = tabOrder();
		if (!order.length) return;
		let i = -1;
		for (let k = 0; k < order.length; k++) if (order[k] === from) i = k;
		const next = back ? order[i <= 0 ? order.length - 1 : i - 1] : order[i < 0 || i >= order.length - 1 ? 0 : i + 1];
		if (next) {
			reveal(next);
			focusEl(next, { preventScroll: true });
		}
	}
	var ACTIVATES = {
		button: true,
		link: true,
		checkbox: true,
		radio: true,
		switch: true,
		tab: true,
		menuitem: true,
		option: true
	};
	/** Presses a key (or combination) on the focused element, with the browser's default action. */
	function press(el, combo) {
		const c = parseCombo(combo);
		const target = el ?? docBody(DOC) ?? DOC;
		const printable = c.key.length === 1 && !c.ctrl && !c.meta && !c.alt;
		const editable = !!el && isEditable(el);
		if (el && editable && printable && isSensitive(el)) guardField(el);
		const down = keyEvent("keydown", target, c);
		if (down && (printable || c.key === "Enter") && !c.ctrl && !c.meta) keyEvent("keypress", target, c);
		if (down && el) {
			const tag = localName(el);
			const role = roleOf(el);
			if (c.key === "Enter" && !c.ctrl && !c.meta && !c.alt) {
				if (tag === "textarea") exec("insertText", "\n");
				else if (editable && isContentEditable(el)) exec("insertParagraph");
				else if (tag === "input" && editable) submitForm(el);
				else if (ACTIVATES[role] === true && role !== "checkbox" && role !== "radio") activate(el);
			} else if (c.key === "Tab") moveFocus(el, c.shift);
			else if (c.key === " " && !editable && ACTIVATES[role] === true) activate(el);
			else if ((c.key === "Backspace" || c.key === "Delete") && editable) exec(c.key === "Backspace" ? "delete" : "forwardDelete");
			else if ((c.ctrl || c.meta) && strLower(c.key) === "a" && editable) exec("selectAll");
			else if (printable && editable && !isDisabled(el) && !isReadOnly(el)) exec("insertText", c.key);
		} else if (down && !el && c.key === "Tab") moveFocus(null, c.shift);
		keyEvent("keyup", target, c);
	}
	function activate(el) {
		dispatch(el, new MouseEventCtor("click", {
			bubbles: true,
			cancelable: true,
			composed: true,
			view: WIN,
			detail: 0
		}));
	}
	/** Enter in a form field: the form's implicit submission. */
	function submitForm(el) {
		const form = formOf(el);
		if (!form) return;
		const btn = formQuerySelector(form, "button:not([type=\"button\"]):not([type=\"reset\"]), input[type=\"submit\"], input[type=\"image\"]");
		if (btn && isDisabled(btn)) return;
		if (formRequestSubmit) formRequestSubmit(form, btn);
		else if (btn) activate(btn);
	}
	/** The element to scroll for a step: the scrollable box at the middle of the screen, else the page. */
	function scroller(vertical) {
		let el = docElementFromPoint(DOC, innerWidth(WIN) / 2, innerHeight(WIN) / 2);
		for (let i = 0; el && i < 100; i++) {
			if (nodeType(el) === 1) {
				const e = el;
				const o = css(style(e), vertical ? "overflow-y" : "overflow-x");
				const room = vertical ? scrollHeight(e) - clientHeight(e) : scrollWidth(e) - clientWidth(e);
				if ((o === "auto" || o === "scroll" || o === "overlay") && room > 1) return e;
			}
			const p = parentNode(el);
			el = p && nodeType(p) === 11 ? shadowHost(p) : p;
		}
		return null;
	}
	function scroll(direction, amount) {
		const vertical = direction === "up" || direction === "down";
		const sign = direction === "up" || direction === "left" ? -1 : 1;
		const opts = vertical ? {
			top: sign * amount,
			left: 0,
			behavior: "instant"
		} : {
			top: 0,
			left: sign * amount,
			behavior: "instant"
		};
		const box = scroller(vertical);
		const pos = () => box ? vertical ? scrollTop(box) : scrollLeft(box) : vertical ? scrollY(WIN) : scrollX(WIN);
		const before = pos();
		if (box) elScrollBy(box, opts);
		else winScrollBy(WIN, opts);
		return pos() !== before ? `Scrolled ${direction}.` : `Scrolled ${direction}; already at the end.`;
	}
	/** Puts a file into an upload field. */
	function upload(el, name, mediaType, data) {
		if (localName(el) !== "input" || inputType(el) !== "file") throw new Fail("not_file_input", "That element isn't an upload field.");
		if (!DataTransferCtor || !FileCtor) throw new Fail("unsupported", "This browser can't put files into upload fields.");
		let bin;
		try {
			bin = atobFn(data);
		} catch {
			throw new Fail("error", "The file data isn't valid base64.");
		}
		const bytes = new Uint8(bin.length);
		for (let i = 0; i < bin.length; i++) bytes[i] = strCode(bin, i);
		const dt = new DataTransferCtor();
		itemsAdd(dataTransferItems(dt), new FileCtor([bytes], name, { type: mediaType }));
		setInputFiles(el, dataTransferFiles(dt));
		fire(el, "input");
		fire(el, "change");
	}
	var DOWNLOAD_MAX = 20971520;
	function filenameFrom(cd) {
		const lower = strLower(cd);
		let i = strIndexOf(lower, "filename*=");
		let star = true;
		if (i < 0) {
			i = strIndexOf(lower, "filename=");
			star = false;
		}
		if (i < 0) return "";
		let v = strSlice(cd, i + (star ? 10 : 9));
		const semi = strIndexOf(v, ";");
		if (semi >= 0) v = strSlice(v, 0, semi);
		v = strTrim(v);
		if (star) {
			const q = strIndexOf(v, "''");
			if (q >= 0) v = strSlice(v, q + 2);
		}
		if (startsWith(v, "\"")) v = strSlice(v, 1, v.length - (v[v.length - 1] === "\"" ? 1 : 0));
		try {
			return decodeUri(v);
		} catch {
			return v;
		}
	}
	function base64(bytes) {
		let bin = "";
		for (let i = 0; i < bytes.length; i += 32768) bin += reflectApply$1(fromCharCode, null, u8Subarray(bytes, i, mathMin(i + 32768, bytes.length)));
		return btoaFn(bin);
	}
	/** Fetches [url] with the page's own sign-in; refuses files over [max] bytes. */
	async function download(url, max) {
		let u;
		try {
			u = new URLCtor(url, locHref(LOCATION));
		} catch {
			throw new Fail("error", "That isn't a web address.");
		}
		const proto = urlProtocol(u);
		if (proto !== "https:" && proto !== "http:" && proto !== "blob:" && proto !== "data:") throw new Fail("unsupported", "Only web addresses can be downloaded.");
		let res;
		try {
			res = await fetchFn(urlHref(u), { credentials: "include" });
		} catch {
			throw new Fail("error", "The download didn't start (the site refused it or is unreachable).");
		}
		if (!responseOk(res)) throw new Fail("error", `The site answered ${responseStatus(res)}.`);
		const headers = responseHeaders(res);
		const len = num(headersGet(headers, "content-length") || 0);
		const tooBig = () => new Fail("too_large", `The file is over ${mathMax(1, max / 1048576 | 0)} MB.`);
		if (len > max) throw tooBig();
		const body = responseBody(res);
		const chunks = list();
		let total = 0;
		if (body) {
			const reader = streamGetReader(body);
			for (;;) {
				const r = await readerRead(reader);
				if (r.done) break;
				const v = r.value;
				total += v.length;
				if (total > max) {
					readerCancel(reader).catch(() => {});
					throw tooBig();
				}
				push(chunks, v);
			}
		}
		const bytes = new Uint8(total);
		let off = 0;
		for (let i = 0; i < chunks.length; i++) {
			const c = chunks[i];
			u8Set(bytes, c, off);
			off += c.length;
		}
		const finalUrl = responseUrl(res) || urlHref(u);
		let name = filenameFrom(headersGet(headers, "content-disposition") ?? "");
		if (!name) try {
			const p = urlPathname(new URLCtor(finalUrl));
			let last = "";
			for (let i = p.length - 1; i >= 0 && p[i] !== "/"; i--) last = p[i] + last;
			name = decodeUri(last);
		} catch {}
		const ct = headersGet(headers, "content-type") ?? "";
		const semi = strIndexOf(ct, ";");
		return {
			name: name || "download",
			media_type: strTrim(semi >= 0 ? strSlice(ct, 0, semi) : ct) || "application/octet-stream",
			data: base64(bytes)
		};
	}
	/** The focused element (in this frame) for type and press, or the reason it can't be used. */
	function focusedForTyping() {
		const f = focusedHere();
		if (f.closedShadow) throw new Fail("out_of_sight", "Focus is inside part of the page Casama can't see into. Ask the person to type it.");
		return f.el;
	}
	// src/frames.ts
	/**
	* Talking to the agent in a child frame. The parent hands the child one end of a MessageChannel
	* (`iframe.contentWindow.postMessage`); the child takes it only from its direct parent, with the
	* secret native gave this page when there is one, and hides the message from the page's own
	* listeners. Requests and answers are JSON strings on that port.
	*/
	/** The marker on connect messages. */
	var CONNECT = "__casamaPageAgent";
	var secret = "";
	function setSecret(s) {
		secret = s;
	}
	function getSecret() {
		return secret;
	}
	var links = new WeakMapCtor();
	function contentWindowOf(el) {
		try {
			return localName(el) === "frame" ? frameContentWindow(el) : iframeContentWindow(el);
		} catch {
			return null;
		}
	}
	/** Sends one request to a child frame; null when it doesn't answer in [timeout] ms. */
	function request(link, cmd, args, timeout) {
		link.seq += 1;
		const id = `f${link.seq}`;
		return new PromiseCtor((resolve) => {
			link.pending[id] = resolve;
			setTimeoutFn(() => {
				if (link.pending[id]) {
					delete link.pending[id];
					resolve(null);
				}
			}, timeout);
			try {
				portPostMessage(link.port, jsonStringify({
					id,
					cmd,
					args
				}));
			} catch {
				delete link.pending[id];
				resolve(null);
			}
		});
	}
	/** A fresh link to the agent in [frameEl]; null when nothing answers within [timeout] ms. */
	async function connect(frameEl, timeout) {
		const win = contentWindowOf(frameEl);
		if (!win || !MessageChannelCtor) return null;
		const ch = new MessageChannelCtor();
		const port = channelPort1(ch);
		const link = {
			port,
			pending: record(),
			seq: 0
		};
		addListener(port, "message", (e) => {
			let a = null;
			try {
				const d = messageData(e);
				a = typeof d === "string" ? jsonParse(d) : null;
			} catch {}
			if (!a || typeof a.id !== "string") return;
			const done = link.pending[a.id];
			if (!done) return;
			delete link.pending[a.id];
			done(a);
		});
		portStart(port);
		try {
			winPostMessage(win, {
				[CONNECT]: "connect",
				secret
			}, "*", [channelPort2(ch)]);
		} catch {
			return null;
		}
		if (!(await request(link, "ping", {}, timeout))?.ok) {
			portClose(port);
			return null;
		}
		weakMapSet(links, frameEl, link);
		return link;
	}
	/** The last link to [frameEl], or a new one. */
	async function linkFor(frameEl, timeout) {
		const known = weakMapGet(links, frameEl);
		if (known) {
			if ((await request(known, "ping", {}, timeout))?.ok) return known;
		}
		return connect(frameEl, timeout);
	}
	// src/page.ts
	/**
	* One frame's snapshot and readable text, walked from the DOM in the shape `formatSnapshot` and
	* `readableText` (apps/extension/src/lib/act/snapshot.ts) give from Chrome's accessibility tree.
	* Frames inside are collected for the caller, which asks each one for its own part.
	*/
	var VALUE_ROLES = {
		textbox: true,
		searchbox: true,
		combobox: true,
		spinbutton: true,
		slider: true
	};
	var NORMAL = 0;
	var INSIDE_INTERACTIVE = 1;
	var INSIDE_CONTENT = 2;
	function indent(depth, interactiveOnly) {
		if (interactiveOnly) return "";
		let s = "";
		for (let i = 0; i < depth && i < 40; i++) s += "  ";
		return s;
	}
	function isFrame(el) {
		const t = localName(el);
		return t === "iframe" || t === "frame";
	}
	function frameVisible(el) {
		const r = getRect(el);
		return rectWidth(r) >= 1 && rectHeight(r) >= 1;
	}
	/** This frame's snapshot lines, and the visible frames inside it (in page order). */
	function snapshotLines(interactiveOnly, maxLines) {
		const lines = list();
		const frames = list();
		const focused = focusedHere().el;
		let trimmed = false;
		const walk = (n, depth, mode, level) => {
			if (level > 200) return;
			const cs = kids(n);
			for (let i = 0; i < cs.length; i++) {
				if (lines.length >= maxLines) {
					trimmed = true;
					return;
				}
				const c = cs[i];
				const t = nodeType(c);
				if (t === 3) {
					if (mode !== NORMAL || interactiveOnly) continue;
					const v = nodeValue(c) ?? "";
					if (!strTrim(v) || textHidden(c, n)) continue;
					push(lines, {
						pre: `${indent(depth, false)}- text ${quote(clean(v))}`,
						post: ""
					});
					continue;
				}
				if (t !== 1) continue;
				const el = c;
				if (isSkipped(el) || selfHidden(el)) continue;
				if (isFrame(el)) {
					if (frames.length < 20 && frameVisible(el)) push(frames, el);
					continue;
				}
				const role = roleOf(el);
				if (INTERACTIVE[role] === true) {
					const name = nameOf(el, role);
					const value = VALUE_ROLES[role] === true ? clean(shownValue(el, role), 80) : "";
					push(lines, {
						pre: `${indent(depth, interactiveOnly)}- ${role}${name ? ` ${quote(name)}` : ""} `,
						target: el,
						post: `${flagsOf(el, role, focused)}${value ? `: ${quote(value)}` : ""}`
					});
					const tag = localName(el);
					if (tag !== "select" && tag !== "input" && tag !== "textarea") walk(el, depth + 1, INSIDE_INTERACTIVE, level + 1);
					continue;
				}
				if (mode !== INSIDE_INTERACTIVE && !interactiveOnly && CONTENT[role] === true) {
					const name = nameOf(el, role);
					if (name) {
						const label = role === "image" ? "img" : role;
						push(lines, {
							pre: `${indent(depth, false)}- ${label} ${quote(name)}${flagsOf(el, role, null)}`,
							post: ""
						});
						walk(el, depth + 1, INSIDE_CONTENT, level + 1);
						continue;
					}
				}
				walk(el, depth, mode, level + 1);
			}
		};
		const root = docElement(DOC);
		if (root && !selfHidden(root)) walk(root, 0, NORMAL, 0);
		return {
			lines,
			frames,
			trimmed
		};
	}
	var BLOCKS = {
		paragraph: true,
		listitem: true,
		row: true,
		heading: true,
		blockquote: true,
		article: true,
		section: true,
		main: true,
		region: true
	};
	/**
	* This frame's visible text: headings as "#" lines, fields as `[name]`, hidden text left out.
	* Returns the frames inside it too.
	*/
	function readLines(max) {
		const out = list();
		const frames = list();
		let line = "";
		let size = 0;
		const flush = () => {
			const t = clean(line, 1e5);
			if (t) {
				push(out, t);
				size += t.length + 1;
			}
			line = "";
		};
		const walk = (n, level) => {
			if (level > 200) return;
			const cs = kids(n);
			for (let i = 0; i < cs.length; i++) {
				if (size > max) return;
				const c = cs[i];
				const t = nodeType(c);
				if (t === 3) {
					const v = nodeValue(c) ?? "";
					if (!strTrim(v) || textHidden(c, n)) continue;
					line += ` ${v}`;
					continue;
				}
				if (t !== 1) continue;
				const el = c;
				if (isSkipped(el) || selfHidden(el)) continue;
				const tag = localName(el);
				if (isFrame(el)) {
					if (frames.length < 20 && frameVisible(el)) push(frames, el);
					continue;
				}
				if (tag === "br") {
					flush();
					continue;
				}
				const role = roleOf(el);
				if (role === "heading") {
					flush();
					const level = mathMin(headingLevel(el), 6);
					let hashes = "";
					for (let k = 0; k < level; k++) hashes += "#";
					line = `${hashes} ${clean(nameOf(el, role), 300)}`;
					flush();
					continue;
				}
				if (role === "textbox" || role === "searchbox") {
					line += ` [${clean(nameOf(el, role), 80) || "text field"}]`;
					continue;
				}
				if (tag === "select" || tag === "input" || tag === "textarea") continue;
				const block = BLOCKS[role] === true || isBlock(el);
				if (block) flush();
				walk(el, level + 1);
				if (block) flush();
			}
		};
		const root = docElement(DOC);
		if (root && !selfHidden(root)) walk(root, 0);
		flush();
		const text = join(out, "\n");
		return {
			text: text.length > max ? `${strSlice(text, 0, max)}\n… (trimmed)` : text,
			frames
		};
	}
	// src/agent.ts
	/**
	* Commands from native (or from the parent frame's agent): one JSON command in, one JSON answer
	* out. The README is the contract. Refs live in the frame that took the snapshot; refs to elements
	* in a child frame are forwarded to that frame's agent.
	*/
	var refs = record();
	var maxDownload = DOWNLOAD_MAX;
	/** Forget every ref (a new snapshot, or the page is going away). */
	function clearRefs() {
		refs = record();
	}
	/** Lowers the download cap (tests); it can't be raised past 20 MB. */
	function setDownloadCap(n) {
		maxDownload = mathMin(n, DOWNLOAD_MAX);
	}
	/** Own properties only, into a record with no prototype: a page can't plant inherited fields. */
	function own(v) {
		const out = record();
		if (!v || typeof v !== "object" || isArray(v)) return out;
		const keys = objectKeys(v);
		for (let i = 0; i < keys.length; i++) {
			const k = keys[i];
			out[k] = v[k];
		}
		return out;
	}
	var str = (v, d = "") => typeof v === "string" ? v : d;
	var bool = (v, d) => typeof v === "boolean" ? v : d;
	var int = (v, d) => {
		const n = typeof v === "number" ? v : typeof v === "string" ? parseNum(v) : NaN;
		return !isNaNum(n) && n >= 0 ? n - n % 1 : d;
	};
	function wref(el) {
		return new WeakRefCtor(el);
	}
	var now = Date.now;
	var FRAME_TIMEOUT = 1e3;
	var ACT_TIMEOUT = 15e3;
	/** This frame's lines plus each visible child frame's, frames asked in parallel. */
	async function assemble(interactiveOnly, maxLines) {
		resetMemo();
		const own = snapshotLines(interactiveOnly, maxLines);
		const lines = list();
		if (!own.lines.length) push(lines, {
			pre: "(nothing on the page)",
			post: ""
		});
		for (let i = 0; i < own.lines.length; i++) {
			const l = own.lines[i];
			push(lines, {
				pre: l.pre,
				post: l.post,
				target: l.target ? {
					kind: "el",
					el: wref(l.target)
				} : void 0
			});
		}
		let trimmed = own.trimmed;
		const asks = list();
		for (let i = 0; i < own.frames.length; i++) {
			const f = own.frames[i];
			push(asks, (async () => {
				const link = await connect(f, FRAME_TIMEOUT);
				if (!link) return null;
				return {
					link,
					answer: await request(link, "frame_snapshot", {
						interactive_only: interactiveOnly,
						max_lines: maxLines
					}, FRAME_TIMEOUT * 2)
				};
			})());
		}
		for (let i = 0; i < asks.length; i++) {
			const got = await asks[i];
			const frameEl = own.frames[i];
			const remote = got?.answer?.ok ? got.answer.lines : null;
			if (!got || !isArray(remote)) {
				push(lines, {
					pre: "- frame: (not readable)",
					post: ""
				});
				continue;
			}
			if (got.answer?.trimmed === true) trimmed = true;
			if (!remote.length && interactiveOnly) continue;
			push(lines, {
				pre: "- frame:",
				post: ""
			});
			if (!remote.length) push(lines, {
				pre: "(nothing on the page)",
				post: ""
			});
			for (let k = 0; k < remote.length; k++) {
				const r = remote[k];
				if (!isArray(r)) continue;
				const key = typeof r[1] === "string" ? r[1] : "";
				push(lines, {
					pre: str(r[0]),
					post: str(r[2]),
					target: key ? {
						kind: "frame",
						link: got.link,
						key,
						frame: wref(frameEl)
					} : void 0
				});
			}
		}
		return {
			lines,
			trimmed
		};
	}
	/** Numbers the refs e1, e2… and keeps them for later steps. */
	function numberRefs(lines, maxLines) {
		clearRefs();
		const text = list();
		const arrays = list();
		let n = 1;
		for (let i = 0; i < lines.length && text.length < maxLines; i++) {
			const l = lines[i];
			if (l.target) {
				const key = `e${n++}`;
				refs[key] = l.target;
				push(text, `${l.pre}[ref=${key}]${l.post}`);
				push(arrays, [
					l.pre,
					key,
					l.post
				]);
			} else {
				push(text, l.pre + l.post);
				push(arrays, [
					l.pre,
					null,
					l.post
				]);
			}
		}
		return {
			text: join(text, "\n"),
			arrays
		};
	}
	async function snapshot(a) {
		const interactiveOnly = bool(a.interactive_only, true);
		const maxLines = int(a.max_lines, 1500) || 1500;
		const { lines, trimmed } = await assemble(interactiveOnly, maxLines);
		const r = numberRefs(lines, maxLines);
		return {
			text: trimmed || lines.length > maxLines ? `${r.text}\n… (snapshot trimmed)` : r.text,
			...where()
		};
	}
	async function frameSnapshot(a) {
		const interactiveOnly = bool(a.interactive_only, true);
		const maxLines = int(a.max_lines, 1500) || 1500;
		const { lines, trimmed } = await assemble(interactiveOnly, maxLines);
		const kept = list();
		for (let i = 0; i < lines.length; i++) {
			const l = lines[i];
			if (i === 0 && !l.target && l.pre === "(nothing on the page)") continue;
			push(kept, l);
		}
		return {
			lines: numberRefs(kept, maxLines).arrays,
			trimmed: trimmed || kept.length > maxLines
		};
	}
	async function readAll(max) {
		resetMemo();
		const own = readLines(max);
		const parts = list();
		if (own.text) push(parts, own.text);
		const asks = list();
		for (let i = 0; i < own.frames.length; i++) push(asks, (async () => {
			const link = await connect(own.frames[i], FRAME_TIMEOUT);
			return link ? request(link, "frame_read", { max }, FRAME_TIMEOUT * 2) : null;
		})());
		for (let i = 0; i < asks.length; i++) {
			const got = await asks[i];
			const t = got?.ok ? str(got.text) : "";
			if (t) push(parts, t);
		}
		return join(parts, "\n\n");
	}
	function where() {
		return {
			url: locHref(LOCATION),
			title: docTitle(DOC)
		};
	}
	/** The element a ref points at in this frame, or the frame link to forward to. */
	function resolve(ref) {
		const t = refs[ref];
		if (!t) throw new Fail("stale_ref", `There's no ${ref || "ref"} on the page now. Take a new snapshot.`);
		if (t.kind === "el") {
			const el = weakDeref(t.el);
			if (!el || !isConnected(el) || ownerDocument(el) !== DOC) throw new Fail("stale_ref", `${ref} is gone from the page. Take a new snapshot.`);
			return { el };
		}
		const frame = weakDeref(t.frame);
		if (!frame || !isConnected(frame)) throw new Fail("stale_ref", `The frame holding ${ref} is gone. Take a new snapshot.`);
		return {
			link: t.link,
			key: t.key,
			frame
		};
	}
	function checkFingerprint(el, a) {
		const fp = fingerprintOf(factsOf(el));
		const want = str(a.fingerprint);
		if (want && want !== fp) throw new Fail("page_changed", "That element changed since it was checked (its label or kind is different). Take a new snapshot.");
		return fp;
	}
	/** The offset of a frame's content box in this frame's viewport. */
	function frameOffset(frame) {
		const r = getRect(frame);
		const s = style(frame);
		return {
			x: rectLeft(r) + clientLeft(frame) + (parseNum(css(s, "padding-left")) || 0),
			y: rectTop(r) + clientTop(frame) + (parseNum(css(s, "padding-top")) || 0)
		};
	}
	async function forward(link, cmd, a, key) {
		const args = record();
		const keys = objectKeys(a);
		for (let i = 0; i < keys.length; i++) args[keys[i]] = a[keys[i]];
		if (key !== null) args.ref = key;
		const got = await request(link, cmd, args, ACT_TIMEOUT);
		if (!got) throw new Fail("stale_ref", "That frame stopped answering. Take a new snapshot.");
		return got;
	}
	/** Locates a ref inside a child frame and checks the frame itself isn't covered at that point. */
	async function locateInFrame(t, a) {
		reveal(t.frame);
		const got = await forward(t.link, "locate", a, t.key);
		if (!got.ok) return got;
		const off = frameOffset(t.frame);
		const x = off.x + num(got.x);
		const y = off.y + num(got.y);
		if (docElementFromPoint(DOC, x, y) !== t.frame) throw new Fail("covered", "Something else on the page covers that element, so it wasn't touched. Take a new snapshot.");
		return {
			...got,
			x,
			y
		};
	}
	var FOCUS_FRAME = (el) => !!el && (localName(el) === "iframe" || localName(el) === "frame");
	/** The focused element here, or the frame link holding focus. */
	async function focusTarget() {
		const el = focusedForTyping();
		if (el && FOCUS_FRAME(el)) {
			const link = await linkFor(el, FRAME_TIMEOUT);
			if (!link) throw new Fail("out_of_sight", "Focus is in a part of the page Casama can't see into (another site's frame). Ask the person to do this step.");
			return { link };
		}
		return { el };
	}
	var COMMANDS = {
		async ping() {
			return {};
		},
		snapshot,
		frame_snapshot: frameSnapshot,
		async read(a) {
			return {
				text: await readAll(int(a.max, 6e4) || 6e4),
				...where()
			};
		},
		async frame_read(a) {
			return { text: await readAll(int(a.max, 6e4) || 6e4) };
		},
		async url() {
			return where();
		},
		async probe(a) {
			if (a.focused === true) {
				const t = await focusTarget();
				if ("link" in t) return forward(t.link, "probe", a, null);
				if (!t.el) throw new Fail("not_editable", "Nothing on the page has focus.");
				resetMemo();
				const facts = factsOf(t.el);
				return {
					facts,
					fingerprint: fingerprintOf(facts)
				};
			}
			const r = resolve(str(a.ref));
			if ("link" in r) return forward(r.link, "probe", a, r.key);
			resetMemo();
			const facts = factsOf(r.el);
			return {
				facts,
				fingerprint: fingerprintOf(facts)
			};
		},
		async locate(a) {
			const r = resolve(str(a.ref));
			if ("link" in r) return locateInFrame(r, a);
			resetMemo();
			const fingerprint = checkFingerprint(r.el, a);
			const { x, y } = locate(r.el);
			return {
				x,
				y,
				fingerprint
			};
		},
		async click(a) {
			const r = resolve(str(a.ref));
			if ("link" in r) {
				const at = await locateInFrame(r, a);
				if (!at.ok) return at;
				return forward(r.link, "click", a, r.key);
			}
			resetMemo();
			checkFingerprint(r.el, a);
			const facts = factsOf(r.el);
			const { x, y, hit } = locate(r.el);
			if (a.synthetic !== false) clickAt(hit, x, y);
			return { text: `Clicked "${facts.name || facts.role || facts.tag}".` };
		},
		async fill(a) {
			const r = resolve(str(a.ref));
			if ("link" in r) return forward(r.link, "fill", a, r.key);
			resetMemo();
			checkFingerprint(r.el, a);
			const facts = factsOf(r.el);
			const note = fill(r.el, str(a.text));
			if (includes(note, "Picked")) return { text: note };
			return { text: `Filled "${facts.name || facts.role}".${note}` };
		},
		async type(a) {
			const t = await focusTarget();
			if ("link" in t) return forward(t.link, "type", a, null);
			if (!t.el) throw new Fail("not_editable", "Nothing that takes text has focus. Click or fill a field first.");
			resetMemo();
			checkFingerprint(t.el, a);
			guardField(t.el);
			typeInto(t.el, str(a.text));
			return { text: "Typed." };
		},
		async press(a) {
			const key = str(a.key);
			if (!key) throw new Fail("error", "No key to press.");
			const t = await focusTarget();
			if ("link" in t) return forward(t.link, "press", a, null);
			resetMemo();
			if (t.el) checkFingerprint(t.el, a);
			press(t.el, key);
			return { text: `Pressed ${key}.` };
		},
		async scroll(a) {
			const d = str(a.direction, "down");
			if (d !== "up" && d !== "down" && d !== "left" && d !== "right") throw new Fail("error", "Scroll up, down, left or right.");
			return { text: scroll(d, int(a.amount, 600) || 600) };
		},
		async wait(a) {
			const text = str(a.text);
			const ms = mathMin(int(a.ms, text ? 3e4 : 1e3), 3e4);
			if (!text) {
				await sleep(ms);
				return { text: "Done waiting." };
			}
			const until = now() + ms;
			for (;;) {
				if (includes(await readAll(2e5), text)) return { text: `"${text}" is on the page.` };
				if (now() >= until) break;
				await sleep(500);
			}
			throw new Fail("timeout", `"${text}" didn't show up within ${mathMin(ms / 1e3, 30)} seconds.`);
		},
		async extract() {
			const v = extractTables();
			return { text: typeof v === "string" ? v : jsonStringify(v, null, 1) };
		},
		async upload(a) {
			const r = resolve(str(a.ref));
			if ("link" in r) return forward(r.link, "upload", a, r.key);
			const name = str(a.name, "file");
			upload(r.el, name, str(a.media_type, "application/octet-stream"), str(a.data));
			return { text: `Put ${name} in the upload field.` };
		},
		async download(a) {
			const url = str(a.url);
			if (!url) throw new Fail("error", "No address to download.");
			const file = await download(url, typeof a.max_bytes === "number" ? mathMin(a.max_bytes, maxDownload) : maxDownload);
			return {
				text: `Downloaded ${file.name}.`,
				file
			};
		}
	};
	/** Runs one command and gives its answer. Never throws. */
	async function handle(command) {
		let c;
		try {
			c = own(typeof command === "string" ? jsonParse(command) : command);
		} catch {
			return {
				id: null,
				ok: false,
				code: "error",
				message: "The command isn't valid JSON."
			};
		}
		const id = typeof c.id === "string" || typeof c.id === "number" ? c.id : null;
		const cmd = str(c.cmd);
		const run = COMMANDS[cmd];
		if (!run) return {
			id,
			ok: false,
			code: "unsupported",
			message: `Unknown command "${cmd}".`
		};
		try {
			const result = await run(own(c.args));
			if (result && result.ok === false && "code" in result) return {
				...result,
				id
			};
			return {
				...result,
				id,
				ok: true
			};
		} catch (e) {
			if (isFail(e)) return {
				id,
				ok: false,
				code: e.code,
				message: e.message
			};
			return {
				id,
				ok: false,
				code: "error",
				message: `The page script failed: ${e instanceof Error ? e.message : str(e, "unknown error")}`
			};
		}
	}
	/** A JSON-safe copy (fresh plain objects, nothing the page could have touched). */
	function plain(a) {
		return jsonParse(jsonStringify(a));
	}
	// src/main.ts
	/**
	* The page agent's entry point (docs/PHONE-BROWSER-PLAN.md §8.3). Built to one IIFE,
	* `client/assets/app_browser/page_agent.js`, that the phone app runs in an isolated script world of
	* every frame at document start. It defines one global, `__casamaPageAgent`, and when native gave
	* it a `casamaNative` port (Android's web message listener) it answers commands there too.
	*/
	var VERSION = "1";
	var reflectApply = Reflect.apply;
	/** Reads (and removes) a global native set up before this script, so page scripts can't reach it. */
	function takeGlobal(name) {
		const d = getOwnDesc(WIN, name);
		if (!d) return void 0;
		const v = "value" in d ? d.value : void 0;
		try {
			delete WIN[name];
		} catch {}
		return v;
	}
	function install() {
		if (getOwnDesc(WIN, "__casamaPageAgent")) return;
		const config = takeGlobal("__casamaPageAgentConfig");
		if (config && typeof config === "object") {
			const s = getOwnDesc(config, "secret")?.value;
			if (typeof s === "string") setSecret(s);
			const cap = getOwnDesc(config, "downloadCap")?.value;
			if (typeof cap === "number" && cap > 0) setDownloadCap(cap);
		}
		const run = async (command) => plain(await handle(command));
		defineProp(WIN, "__casamaPageAgent", {
			value: freeze({
				handle: run,
				version: VERSION
			}),
			writable: false,
			configurable: false,
			enumerable: false
		});
		addListener(WIN, "pagehide", () => clearRefs(), true);
		addListener(WIN, "message", (e) => {
			const d = messageData(e);
			if (!d || typeof d !== "object") return;
			if (getOwnDesc(d, "__casamaPageAgent")?.value !== "connect") return;
			stopImmediate(e);
			if (IS_TOP || messageSource(e) !== PARENT) return;
			const secret = getSecret();
			if (secret && getOwnDesc(d, "secret")?.value !== secret) return;
			const port = messagePorts(e)[0];
			if (!port) return;
			addListener(port, "message", (m) => {
				const data = messageData(m);
				if (typeof data !== "string") return;
				(async () => {
					const answer = await handle(data);
					try {
						portPostMessage(port, jsonStringify(answer));
					} catch {}
				})();
			});
			portStart(port);
		}, true);
		const native = takeGlobal("casamaNative");
		if (native && typeof native === "object") {
			const post = native.postMessage;
			if (typeof post !== "function") return;
			const send = (v) => {
				try {
					reflectApply(post, native, [jsonStringify(v)]);
				} catch {}
			};
			const onCommand = (e) => {
				const data = e && typeof e === "object" ? e.data : void 0;
				if (typeof data !== "string") return;
				let parsed;
				try {
					parsed = jsonParse(data);
				} catch {
					send({
						id: null,
						ok: false,
						code: "error",
						message: "The command isn't valid JSON."
					});
					return;
				}
				(async () => send(await handle(parsed)))();
			};
			const add = native.addEventListener;
			if (typeof add === "function") reflectApply(add, native, ["message", onCommand]);
			else native.onmessage = onCommand;
			send({
				hello: true,
				frame: IS_TOP ? "top" : "child",
				href: locHref(LOCATION)
			});
		}
	}
	try {
		install();
	} catch {}
})();
