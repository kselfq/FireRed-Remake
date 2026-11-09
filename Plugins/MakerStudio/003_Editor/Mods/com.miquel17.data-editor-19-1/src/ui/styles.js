export const CSS = `
.pepbs-root {
  --pepbs-accent: var(--accent, #6d8cff);
  --pepbs-danger: var(--danger, #ef6464);
  --pepbs-warning: #d69a35;
  position: relative; display: flex; flex-direction: column; height: 100%; min-height: 0; overflow: hidden;
  color: var(--text-primary); background: var(--bg-primary); font: 13px/1.42 inherit;
}
.pepbs-root * { box-sizing: border-box; }
.pepbs-toolbar {
  min-height: 52px; display: flex; align-items: center; gap: 10px; padding: 8px 14px;
  border-bottom: 1px solid var(--border); background: var(--bg-secondary);
}
.pepbs-brand { display: flex; align-items: center; gap: 10px; min-width: 260px; }
.pepbs-mark { width: 28px; height: 28px; display: grid; flex: 0 0 28px; place-items: center; overflow: hidden; background: transparent; }
.pepbs-mark img { width: 100%; height: 100%; display: block; object-fit: cover; object-position: 50% 28%; }
.pepbs-title { font-size: 14px; font-weight: 720; letter-spacing: -.01em; }
.pepbs-version { color: var(--text-tertiary); font-size: 11px; }
.pepbs-spacer { flex: 1; }
.pepbs-visually-hidden { position: absolute!important; width: 1px!important; height: 1px!important; padding: 0!important; overflow: hidden!important; clip: rect(0,0,0,0)!important; white-space: nowrap!important; border: 0!important; }
.pepbs-language { height: 29px; display: inline-flex; align-items: center; gap: 2px; padding: 2px; border: 1px solid var(--border); border-radius: 6px; color: var(--text-tertiary); background: var(--bg-tertiary); }
.pepbs-language-icon { width: 22px; height: 22px; display: grid; place-items: center; }
.pepbs-language-icon svg { width: 14px; height: 14px; fill: none; stroke: currentColor; stroke-width: 1.6; stroke-linecap: round; }
.pepbs-language button { min-width: 29px; height: 23px; padding: 0 6px; border: 0; border-radius: 4px; color: var(--text-tertiary); background: transparent; cursor: pointer; font: inherit; font-size: 9px; font-weight: 700; line-height: 1; }
.pepbs-language button:hover { color: var(--text-primary); }
.pepbs-language button.is-active { color: var(--text-primary); background: var(--bg-primary); box-shadow: 0 1px 2px rgba(0,0,0,.16); }
.pepbs-change-review { position: relative; }
.pepbs-save-meta { min-height: 29px; display: inline-flex; align-items: center; gap: 6px; padding: 4px 7px; border: 1px solid transparent; border-radius: 5px; color: var(--text-secondary); background: transparent; cursor: pointer; font: inherit; font-size: 11px; white-space: nowrap; }
.pepbs-save-meta:not(:disabled):hover, .pepbs-save-meta[aria-expanded="true"] { color: var(--text-primary); border-color: var(--border); background: var(--bg-tertiary); }
.pepbs-save-meta:not(:disabled)::after { content: ""; width: 5px; height: 5px; margin: -3px 1px 0 3px; border-right: 1.5px solid currentColor; border-bottom: 1.5px solid currentColor; transform: rotate(45deg); transition: transform 140ms ease, margin 140ms ease; }
.pepbs-save-meta[aria-expanded="true"]::after { margin-top: 3px; transform: rotate(225deg); }
.pepbs-save-meta:disabled { padding-inline: 0; color: var(--text-tertiary); cursor: default; }
.pepbs-save-warning-count { min-width: 17px; height: 17px; display: grid; place-items: center; padding: 0 5px; border-radius: 99px; color: var(--pepbs-warning); background: color-mix(in srgb, var(--pepbs-warning) 13%, transparent); font-size: 9px; font-weight: 750; font-variant-numeric: tabular-nums; }
.pepbs-changes-panel { position: absolute; z-index: 80; top: calc(100% + 9px); right: 0; width: min(430px, calc(100vw - 28px)); max-height: min(520px, calc(100vh - 88px)); overflow: hidden; border: 1px solid var(--border); border-radius: 8px; background: var(--bg-secondary); box-shadow: 0 18px 42px rgba(0,0,0,.3); animation: pepbs-popover-in 170ms ease-out; }
.pepbs-changes-panel[hidden] { display: none; }
.pepbs-changes-head { min-height: 42px; display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 9px 12px; border-bottom: 1px solid var(--border); }
.pepbs-changes-head strong { font-size: 12px; }
.pepbs-changes-head .pepbs-changes-count { min-width: 22px; height: 20px; display: grid; place-items: center; padding-inline: 6px; border-radius: 99px; color: var(--pepbs-accent); background: color-mix(in srgb, var(--pepbs-accent) 12%, transparent); font-size: 9px; font-variant-numeric: tabular-nums; }
.pepbs-changes-head-actions { display: flex; min-width: 0; align-items: center; justify-content: flex-end; gap: 7px; }
.pepbs-changes-head-counts { display: flex; align-items: center; gap: 5px; }
.pepbs-discard-all { flex: 0 0 auto; min-height: 25px; padding: 3px 7px; color: var(--pepbs-danger); }
.pepbs-discard-all:hover:not(:disabled) { border-color: color-mix(in srgb, var(--pepbs-danger) 52%, var(--border)); color: #ff9ba2; background: color-mix(in srgb, var(--pepbs-danger) 8%, transparent); }
.pepbs-changes-issue-count { min-height: 20px; display: inline-flex; align-items: center; padding: 0 7px; border-radius: 99px; font-size: 9px; font-weight: 650; }
.pepbs-changes-issue-count.is-error { color: #ff8991; background: color-mix(in srgb,var(--pepbs-danger) 15%,transparent); }
.pepbs-changes-issue-count.is-warning { color: #e6b55d; background: color-mix(in srgb,#d89d3c 15%,transparent); }
.pepbs-changes-body { max-height: min(470px, calc(100vh - 132px)); overflow-y: auto; }
.pepbs-warning-head { min-height: 32px; display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 7px 12px 5px; color: var(--pepbs-warning); background: color-mix(in srgb, var(--pepbs-warning) 5%, transparent); }
.pepbs-warning-head strong { font-size: 10px; letter-spacing: .04em; text-transform: uppercase; }
.pepbs-warning-head span { font-size: 9px; font-variant-numeric: tabular-nums; }
.pepbs-warning-list { border-bottom: 1px solid var(--border); }
.pepbs-warning-row { width: 100%; min-height: 58px; display: grid; grid-template-columns: 28px minmax(0,1fr) 16px; align-items: center; gap: 9px; padding: 8px 11px; border: 0; border-top: 1px solid color-mix(in srgb, var(--border) 72%, transparent); color: var(--text-primary); background: color-mix(in srgb, var(--pepbs-warning) 3%, transparent); cursor: pointer; font: inherit; text-align: left; }
.pepbs-warning-row:hover { background: color-mix(in srgb, var(--pepbs-warning) 9%, transparent); }
.pepbs-warning-row:focus-visible { outline: 2px solid color-mix(in srgb, var(--pepbs-warning) 70%, transparent); outline-offset: -3px; }
.pepbs-warning-row.is-error { background: color-mix(in srgb,var(--pepbs-danger) 4%,transparent); }
.pepbs-warning-row.is-error:hover { background: color-mix(in srgb,var(--pepbs-danger) 10%,transparent); }
.pepbs-warning-row.is-error:focus-visible { outline-color: color-mix(in srgb,var(--pepbs-danger) 70%,transparent); }
.pepbs-warning-row.is-error .pepbs-warning-mark { color: #ff8991; border-color: color-mix(in srgb,var(--pepbs-danger) 48%,var(--border)); background: color-mix(in srgb,var(--pepbs-danger) 11%,transparent); }
.pepbs-warning-row.is-error .pepbs-warning-open { color: #ff8991; }
.pepbs-warning-mark { width: 26px; height: 26px; display: grid; place-items: center; border: 1px solid color-mix(in srgb, var(--pepbs-warning) 45%, var(--border)); border-radius: 50%; color: var(--pepbs-warning); background: color-mix(in srgb, var(--pepbs-warning) 10%, transparent); font-size: 11px; font-weight: 800; }
.pepbs-warning-copy { min-width: 0; display: flex; flex-direction: column; }
.pepbs-warning-copy strong { overflow: hidden; color: var(--text-primary); font-size: 11px; font-weight: 650; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-warning-copy small { display: -webkit-box; margin-top: 2px; overflow: hidden; color: var(--text-secondary); font-size: 9px; line-height: 1.35; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
.pepbs-warning-open { color: var(--pepbs-warning); font-size: 18px; text-align: center; }
.pepbs-changes-list { padding: 3px 0; }
.pepbs-change-row { min-height: 52px; display: grid; grid-template-columns: minmax(0,1fr) auto; align-items: stretch; gap: 5px; padding: 3px 6px 3px 3px; border-bottom: 1px solid color-mix(in srgb, var(--border) 72%, transparent); }
.pepbs-change-row:last-child { border-bottom: 0; }
.pepbs-change-row:has(.pepbs-change-open:hover) { background: color-mix(in srgb, var(--bg-tertiary) 72%, transparent); }
.pepbs-change-open { min-width: 0; display: grid; grid-template-columns: 28px minmax(0,1fr); align-items: center; gap: 9px; padding: 4px 5px 4px 8px; border: 0; border-radius: 5px; color: inherit; background: transparent; font: inherit; text-align: left; cursor: pointer; }
.pepbs-change-open:hover { background: color-mix(in srgb,var(--bg-hover) 55%,transparent); }
.pepbs-change-open:focus-visible { outline: 2px solid color-mix(in srgb,var(--pepbs-accent) 65%,transparent); outline-offset: -2px; }
.pepbs-change-open:not(button) { cursor: default; }
.pepbs-change-kind { width: 26px; height: 26px; display: grid; place-items: center; border: 1px solid color-mix(in srgb, var(--pepbs-accent) 35%, var(--border)); border-radius: 6px; color: var(--pepbs-accent); background: color-mix(in srgb, var(--pepbs-accent) 8%, transparent); }
.pepbs-change-kind { position: relative; }
.pepbs-change-issue-dot { position: absolute; right: -5px; top: -5px; width: 14px; height: 14px; display: grid; place-items: center; border: 2px solid var(--bg-secondary); border-radius: 50%; color: #fff; font: 800 8px/1 var(--font-family,system-ui); font-style: normal; }
.pepbs-change-issue-dot.is-error { background: var(--pepbs-danger); }
.pepbs-change-issue-dot.is-warning { background: #c98a28; }
.pepbs-change-kind .pepbs-domain-icon { width: 15px; height: 15px; }
.pepbs-change-row.is-created .pepbs-change-kind { color: #61b77a; border-color: color-mix(in srgb, #61b77a 35%, var(--border)); background: color-mix(in srgb, #61b77a 8%, transparent); }
.pepbs-change-row.is-deleted .pepbs-change-kind { color: var(--pepbs-danger); border-color: color-mix(in srgb, var(--pepbs-danger) 35%, var(--border)); background: color-mix(in srgb, var(--pepbs-danger) 8%, transparent); }
.pepbs-change-copy { min-width: 0; display: flex; flex-direction: column; }
.pepbs-change-copy strong, .pepbs-change-copy small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-change-copy strong { color: var(--text-primary); font-size: 11px; font-weight: 650; }
.pepbs-change-copy small { margin-top: 2px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-change-copy .pepbs-change-issue { margin-top: 3px; font-weight: 600; }
.pepbs-change-copy .pepbs-change-issue.is-error { color: #ff8991; }
.pepbs-change-copy .pepbs-change-issue.is-warning { color: #e6b55d; }
.pepbs-change-undo { min-width: 66px; color: var(--pepbs-accent); }
.pepbs-save-error-count,.pepbs-save-warning-count { min-width: 16px; height: 16px; display: inline-grid; place-items: center; margin-left: 5px; border-radius: 99px; font-size: 8px; font-weight: 750; }
.pepbs-save-error-count { color: #fff; background: var(--pepbs-danger); }
@keyframes pepbs-popover-in { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }
.pepbs-btn {
  min-height: 31px; display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 5px 10px;
  border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--bg-tertiary); cursor: pointer;
  font: inherit; font-size: 12px; transition: background-color 140ms ease, border-color 140ms ease, transform 100ms ease;
}
.pepbs-btn:hover:not(:disabled) { border-color: var(--pepbs-accent); background: var(--bg-hover, var(--bg-tertiary)); }
.pepbs-btn:active:not(:disabled) { transform: translateY(1px); }
.pepbs-btn:focus-visible, .pepbs-save-meta:focus-visible, .pepbs-changes-panel:focus-visible, .pepbs-language button:focus-visible, .pepbs-notice-close:focus-visible, .pepbs-input:focus-visible, .pepbs-textarea:focus-visible, .pepbs-nav:focus-visible, .pepbs-tab:focus-visible, .pepbs-ref-toggle:focus-visible, .pepbs-mini:focus-visible, .pepbs-combat-tab:focus-visible, .pepbs-combat-add:focus-visible, .pepbs-segmented button:focus-visible, .pepbs-type-option:focus-visible, .pepbs-category-option:focus-visible, .pepbs-ref-option:focus-visible, .pepbs-dropdown-trigger:focus-visible, .pepbs-dropdown-option:focus-visible, .pepbs-dropdown-search:focus-visible, .pepbs-switch:focus-visible, .pepbs-ebdx-canvas:focus-visible, .pepbs-ebdx-side-tabs button:focus-visible, .pepbs-ebdx-range:focus-visible { outline: 2px solid color-mix(in srgb, var(--pepbs-accent) 65%, transparent); outline-offset: 2px; }
.pepbs-btn:disabled { opacity: .5; cursor: default; }
.pepbs-btn-primary { color: var(--accent-text); border-color: transparent; background: var(--pepbs-accent); font-weight: 650; }
.pepbs-btn-danger { color: var(--pepbs-danger); }
.pepbs-btn-quiet { min-height: 25px; padding: 3px 7px; border-color: transparent; background: transparent; color: var(--text-secondary); }
.pepbs-btn-compact { min-height: 27px; padding: 3px 8px; font-size: 10px; }
.pepbs-body { display: grid; grid-template-columns: 176px minmax(250px, 300px) minmax(480px, 1fr) 250px; flex: 1; min-height: 0; overflow: hidden; }
.pepbs-root.is-ebdx .pepbs-body { grid-template-columns: 176px minmax(230px, 270px) minmax(0, 1fr); }
.pepbs-root.is-ebdx .pepbs-inspector { display: none; }
.pepbs-root.is-connections .pepbs-body { grid-template-columns: 176px minmax(250px,300px) minmax(0,1fr); }
.pepbs-root.is-connections .pepbs-inspector { display: none; }
.pepbs-root.is-connections .pepbs-editor { overflow: hidden; }
.pepbs-rail, .pepbs-catalog, .pepbs-editor, .pepbs-inspector { min-height: 0; }
.pepbs-rail { overflow-y: auto; padding: 12px 8px; border-right: 1px solid var(--border); background: var(--bg-secondary); }
.pepbs-rail-label { margin: 2px 8px 8px; color: var(--text-tertiary); font-size: 10px; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; }
.pepbs-rail-label-secondary { margin-top: 18px; padding-top: 12px; border-top: 1px solid var(--border); }
.pepbs-nav { width: 100%; display: flex; align-items: center; gap: 9px; padding: 9px 10px; border: 0; border-radius: 6px; color: var(--text-secondary); background: transparent; cursor: pointer; text-align: left; }
.pepbs-domain-icon { width: 18px; height: 18px; display: inline-grid; flex: 0 0 auto; place-items: center; color: currentColor; }
.pepbs-domain-icon svg { width: 100%; height: 100%; overflow: visible; }
.pepbs-nav-icon { width: 17px; height: 17px; color: var(--text-tertiary); transition: color 140ms ease, transform 140ms ease; }
.pepbs-nav:hover .pepbs-nav-icon { color: var(--text-secondary); }
.pepbs-nav.is-active .pepbs-nav-icon { color: var(--pepbs-accent); transform: translateX(1px); }
.pepbs-button-icon { width: 13px; height: 13px; color: var(--text-secondary); }
.pepbs-create-record:hover .pepbs-button-icon { color: var(--pepbs-accent); }
.pepbs-nav:hover { color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-nav.is-active { color: var(--text-primary); background: color-mix(in srgb, var(--pepbs-accent) 13%, var(--bg-tertiary)); }
.pepbs-catalog { display: flex; flex-direction: column; border-right: 1px solid var(--border); background: var(--bg-primary); }
.pepbs-catalog-head { padding: 13px 12px 10px; border-bottom: 1px solid var(--border); }
.pepbs-catalog-title { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 9px; }
.pepbs-catalog-heading { min-width: 0; display: flex; flex-direction: column; }
.pepbs-catalog-title strong { color: var(--text-primary); font-size: 13px; }
.pepbs-catalog-title span { color: var(--text-tertiary); font-size: 10px; }
.pepbs-catalog-actions { display: flex; align-items: center; gap: 8px; }
.pepbs-segmented { display: grid; grid-template-columns: 1fr 1fr; padding: 2px; margin-bottom: 9px; border-radius: 6px; background: var(--bg-tertiary); }
.pepbs-segmented button { padding: 5px; border: 0; border-radius: 4px; color: var(--text-secondary); background: transparent; cursor: pointer; font: inherit; font-size: 11px; }
.pepbs-segmented button.is-active { color: var(--text-primary); background: var(--bg-primary); box-shadow: 0 1px 2px rgba(0,0,0,.12); }
.pepbs-search-wrap { position: relative; }
.pepbs-search-wrap::before { content: "⌕"; position: absolute; left: 9px; top: 5px; color: var(--text-tertiary); font-size: 16px; pointer-events: none; }
.pepbs-search { width: 100%; height: 31px; padding: 5px 9px 5px 29px; border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--input-bg, var(--bg-secondary)); font: inherit; font-size: 12px; }
.pepbs-list { flex: 1; min-height: 0; overflow: auto; padding: 5px; }
.pepbs-entry { width: 100%; min-height: 36px; display: grid; grid-template-columns: 30px minmax(60px,1fr) auto; align-items: center; gap: 5px; padding: 7px 5px; border: 0; border-radius: 6px; color: var(--text-primary); background: transparent; cursor: pointer; text-align: left; }
.pepbs-entry.has-no-index { grid-template-columns: minmax(0,1fr) auto; }
.pepbs-entry:hover { background: var(--bg-secondary); }
.pepbs-entry.is-active { background: color-mix(in srgb, var(--pepbs-accent) 14%, var(--bg-secondary)); }
.pepbs-entry-num { color: var(--text-tertiary); font-size: 10px; font-variant-numeric: tabular-nums; text-align: right; }
.pepbs-entry-main { min-width: 0; }
.pepbs-entry-name { display: block; overflow: hidden; color: var(--text-primary); font-size: 12px; font-weight: 620; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-entry-id { display: block; overflow: hidden; color: var(--text-tertiary); font: 9.5px/1.35 ui-monospace, SFMono-Regular, Consolas, monospace; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-battle-count { color: var(--text-tertiary); font-size: 8.5px; white-space: nowrap; }
.pepbs-entry-trailing { display: flex; align-items: center; justify-content: flex-end; gap: 5px; }
.pepbs-entry-types { display: flex; flex-flow: row nowrap; align-items: center; justify-content: flex-end; gap: 3px; }
.pepbs-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--pepbs-accent); }
.pepbs-catalog-foot { min-height: 40px; display: flex; align-items: center; justify-content: space-between; gap: 5px; padding: 6px 9px; border-top: 1px solid var(--border); color: var(--text-tertiary); font-size: 10px; }
.pepbs-editor { overflow: auto; scrollbar-color: var(--border) var(--bg-primary); scrollbar-gutter: stable; background: var(--bg-primary); }
.pepbs-editor::-webkit-scrollbar { width: 10px; height: 10px; }
.pepbs-editor::-webkit-scrollbar-track,.pepbs-editor::-webkit-scrollbar-corner { background: var(--bg-primary); }
.pepbs-editor::-webkit-scrollbar-thumb { min-height: 28px; border: 2px solid var(--bg-primary); border-radius: 99px; background: color-mix(in srgb,var(--border) 78%,var(--text-tertiary)); }
.pepbs-editor::-webkit-scrollbar-thumb:hover { background: color-mix(in srgb,var(--pepbs-accent) 55%,var(--border)); }
.pepbs-empty { height: 100%; display: grid; place-items: center; padding: 30px; color: var(--text-secondary); text-align: center; }
.pepbs-record-head { position: sticky; top: 0; z-index: 4; padding: 16px 20px 0; border-bottom: 1px solid var(--border); background: color-mix(in srgb, var(--bg-primary) 94%, transparent); backdrop-filter: blur(10px); }
.pepbs-record-title { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 13px; }
.pepbs-record-title h2 { margin: 0; font-size: 18px; line-height: 1.15; letter-spacing: -.02em; }
.pepbs-record-title code { display: block; margin-top: 4px; color: var(--text-tertiary); font-size: 10px; }
.pepbs-record-badges { margin-left: auto; display: flex; align-items: center; gap: 6px; }
.pepbs-delete-record { min-height: 24px; margin-left: 2px; border-color: color-mix(in srgb, var(--pepbs-danger) 28%, var(--border)); background: transparent; }
.pepbs-badge { display: inline-flex; align-items: center; min-height: 22px; padding: 2px 7px; border: 1px solid var(--border); border-radius: 99px; color: var(--text-secondary); background: var(--bg-secondary); font-size: 10px; }
.pepbs-badge-dirty { color: var(--pepbs-accent); border-color: color-mix(in srgb, var(--pepbs-accent) 45%, var(--border)); }
.pepbs-badge-error { color: var(--pepbs-danger); border-color: color-mix(in srgb, var(--pepbs-danger) 45%, var(--border)); }
.pepbs-tabs { display: flex; gap: 2px; overflow-x: auto; scrollbar-width: none; }
.pepbs-combat-bar { display: flex; align-items: center; gap: 9px; padding: 8px 0 10px; border-top: 1px solid var(--border); }
.pepbs-combat-label { color: var(--text-tertiary); font-size: 9px; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; }
.pepbs-combat-tabs { display: flex; flex-wrap: wrap; gap: 4px; }
.pepbs-combat-tab, .pepbs-combat-add { min-height: 28px; padding: 4px 8px; border: 1px solid var(--border); border-radius: 5px; color: var(--text-secondary); background: transparent; cursor: pointer; font: inherit; font-size: 10px; transition: background-color 140ms ease, border-color 140ms ease; }
.pepbs-combat-tab:hover, .pepbs-combat-add:hover { color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-combat-tab.is-active { color: var(--pepbs-accent); border-color: color-mix(in srgb, var(--pepbs-accent) 45%, var(--border)); background: color-mix(in srgb, var(--pepbs-accent) 10%, transparent); }
.pepbs-combat-add { padding-inline: 8px; color: var(--pepbs-accent); }
.pepbs-combat-help { margin-left: auto; color: var(--text-tertiary); font-size: 9px; }
.pepbs-tabs::-webkit-scrollbar { display: none; }
.pepbs-tab { padding: 8px 9px 9px; border: 0; border-bottom: 2px solid transparent; color: var(--text-secondary); background: transparent; cursor: pointer; font: inherit; font-size: 11px; white-space: nowrap; }
.pepbs-tab:hover { color: var(--text-primary); }
.pepbs-tab.is-active { color: var(--pepbs-accent); border-bottom-color: var(--pepbs-accent); font-weight: 650; }
.pepbs-form { padding: 20px; }
.pepbs-section-heading { margin: 0 0 15px; font-size: 12px; font-weight: 700; }
.pepbs-grid { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 15px 18px; align-items: start; }
.pepbs-field { min-width: 0; }
.pepbs-field.is-dependency-disabled,.pepbs-world-field.is-dependency-disabled,.pepbs-team-field.is-dependency-disabled,.is-dependency-disabled { opacity: .52; }
.pepbs-field.is-dependency-disabled :is(input,textarea,button),.pepbs-world-field.is-dependency-disabled :is(input,textarea,button),.pepbs-team-field.is-dependency-disabled :is(input,textarea,button),input.is-dependency-disabled { cursor: not-allowed; }
.pepbs-field.is-wide { grid-column: 1 / -1; }
.pepbs-field-group { grid-column: 1 / -1; min-width: 0; display: grid; grid-template-columns: repeat(var(--pepbs-group-columns,2),minmax(0,1fr)); align-items: start; gap: 10px; }
.pepbs-field-group > .pepbs-field { min-width: 0; }
.pepbs-field-group.is-single { width: calc(50% - 9px); justify-self: start; }
.pepbs-field-group[data-field-group="machine"].is-single { width: min(100%,360px); }
.pepbs-field-group[data-field-group="types"],.pepbs-field-group[data-field-group="moveKind"],.pepbs-field-group[data-field-group="machine"] { padding: 9px 10px 10px; border: 1px solid color-mix(in srgb,var(--border) 76%,transparent); border-radius: 7px; background: color-mix(in srgb,var(--bg-tertiary) 38%,transparent); }
.pepbs-field-head { min-height: 19px; display: flex; align-items: center; gap: 6px; margin-bottom: 5px; }
.pepbs-label { color: var(--text-secondary); font-size: 10.5px; font-weight: 650; }
.pepbs-required { color: var(--pepbs-accent); }
.pepbs-inherited { margin-left: auto; overflow: hidden; color: var(--text-tertiary); font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-input, .pepbs-textarea {
  width: 100%; border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--input-bg, var(--bg-secondary)); font: inherit; font-size: 12px;
}
.pepbs-input { height: 32px; padding: 5px 8px; }
.pepbs-input[type="number"] { appearance: textfield; -moz-appearance: textfield; }
.pepbs-input[type="number"]::-webkit-inner-spin-button, .pepbs-input[type="number"]::-webkit-outer-spin-button { margin: 0; appearance: none; -webkit-appearance: none; }
.pepbs-dropdown { position: relative; min-width: 0; width: 100%; }
.pepbs-dropdown-trigger { width: 100%; height: 32px; display: grid; grid-template-columns: minmax(0,1fr) 18px; align-items: center; gap: 8px; padding: 5px 7px 5px 9px; border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--input-bg,var(--bg-secondary)); cursor: pointer; font: inherit; font-size: 11px; text-align: left; transition: border-color 120ms ease,background-color 120ms ease; }
.pepbs-dropdown-trigger:hover { border-color: color-mix(in srgb,var(--pepbs-accent) 52%,var(--border)); }
.pepbs-dropdown.is-open .pepbs-dropdown-trigger { border-color: var(--pepbs-accent); background: color-mix(in srgb,var(--input-bg,var(--bg-secondary)) 94%,var(--pepbs-accent)); }
.pepbs-dropdown-value { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-dropdown-value.is-placeholder { color: var(--text-tertiary); }
.pepbs-dropdown-arrow { width: 7px; height: 7px; justify-self: center; border-right: 1.5px solid var(--text-tertiary); border-bottom: 1.5px solid var(--text-tertiary); transform: translateY(-2px) rotate(45deg); transition: transform 140ms ease; }
.pepbs-dropdown.is-open .pepbs-dropdown-arrow { transform: translateY(2px) rotate(225deg); }
.pepbs-dropdown-menu { position: absolute; z-index: 45; top: 35px; left: 0; width: 100%; min-width: min(250px,calc(100vw - 48px)); overflow: hidden; padding: 5px; border: 1px solid var(--border); border-radius: 7px; background: var(--bg-secondary); box-shadow: 0 14px 34px rgba(0,0,0,.34); animation: pepbs-dropdown-in 120ms ease-out; }
.pepbs-dropdown.opens-up .pepbs-dropdown-menu { top: auto; bottom: 35px; animation-name: pepbs-dropdown-up-in; }
.pepbs-dropdown-menu[hidden] { display: none; }
.pepbs-dropdown-search { width: 100%; height: 30px; margin-bottom: 4px; padding: 5px 8px; border: 1px solid var(--border); border-radius: 5px; color: var(--text-primary); background: var(--input-bg,var(--bg-primary)); font: inherit; font-size: 10px; }
.pepbs-dropdown-options { max-height: 260px; overflow-y: auto; overscroll-behavior: contain; }
.pepbs-dropdown-option { width: 100%; min-height: 32px; display: grid; grid-template-columns: minmax(0,1fr) 18px; align-items: center; gap: 8px; padding: 6px 7px; border: 0; border-radius: 5px; color: var(--text-primary); background: transparent; cursor: pointer; font: inherit; font-size: 10.5px; text-align: left; }
.pepbs-dropdown-option:hover,.pepbs-dropdown-option.is-active { background: var(--bg-tertiary); }
.pepbs-dropdown-check { color: var(--pepbs-accent); font-weight: 800; text-align: center; }
.pepbs-dropdown-empty { padding: 9px 7px; color: var(--text-tertiary); font-size: 10px; }
@keyframes pepbs-dropdown-in { from { opacity: 0; transform: translateY(-3px); } to { opacity: 1; transform: translateY(0); } }
@keyframes pepbs-dropdown-up-in { from { opacity: 0; transform: translateY(3px); } to { opacity: 1; transform: translateY(0); } }
.pepbs-textarea { min-height: 86px; resize: vertical; padding: 8px; }
.pepbs-input:disabled { color: var(--text-tertiary); background: var(--bg-tertiary); cursor: not-allowed; }
.pepbs-type-picker { position: relative; width: 100%; }
.pepbs-type-summary { width: 100%; height: 32px; display: flex; align-items: center; gap: 8px; padding: 3px 28px 3px 7px; overflow: hidden; border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--input-bg, var(--bg-secondary)); cursor: pointer; list-style: none; font-size: 11px; }
.pepbs-type-summary::-webkit-details-marker { display: none; }
.pepbs-type-summary::after, .pepbs-category-summary::after { content: ""; position: absolute; right: 11px; top: 12px; width: 6px; height: 6px; border-right: 1.5px solid var(--text-tertiary); border-bottom: 1.5px solid var(--text-tertiary); transform: rotate(45deg); transition: transform 140ms ease, top 140ms ease; }
.pepbs-type-picker[open] .pepbs-type-summary::after, .pepbs-category-picker[open] .pepbs-category-summary::after { top: 15px; transform: rotate(225deg); }
.pepbs-type-summary:hover, .pepbs-category-summary:hover { border-color: color-mix(in srgb, var(--pepbs-accent) 55%, var(--border)); }
.pepbs-type-picker[open] .pepbs-type-summary, .pepbs-category-picker[open] .pepbs-category-summary { border-color: var(--pepbs-accent); }
.pepbs-type-placeholder { color: var(--text-tertiary); }
.pepbs-type-menu { position: absolute; z-index: 65; top: 35px; left: 0; width: 320px; max-height: 290px; display: grid; grid-template-columns: repeat(3,minmax(0,1fr)); gap: 3px; overflow: auto; padding: 5px; border: 1px solid var(--border); border-radius: 7px; background: var(--bg-secondary); box-shadow: 0 12px 30px rgba(0,0,0,.25); }
.pepbs-type-picker.opens-up .pepbs-type-menu { top: auto; bottom: 35px; }
.pepbs-type-option { width: 100%; min-height: 32px; display: flex; align-items: center; justify-content: center; padding: 4px; border: 0; border-radius: 5px; color: var(--text-primary); background: transparent; cursor: pointer; }
.pepbs-type-option:hover, .pepbs-type-option.is-active { background: var(--bg-tertiary); }
.pepbs-type-option.is-empty { grid-column: 1 / -1; justify-content: flex-start; padding-left: 8px; }
.pepbs-type-logo, .pepbs-category-logo { height: 22px; min-width: 78px; display: inline-flex; flex: 0 0 auto; align-items: center; gap: 5px; padding: 2px 7px 2px 3px; overflow: hidden; border: 1px solid color-mix(in srgb, var(--badge-color) 76%, #fff 8%); border-radius: 999px; color: #fff; background: color-mix(in srgb, var(--badge-color) 82%, #11131d); box-shadow: inset 0 1px rgba(255,255,255,.14); font-size: 8.5px; font-weight: 760; letter-spacing: .025em; text-transform: uppercase; }
.pepbs-type-logo { width: 82px; min-width: 82px; }
.pepbs-type-logo.is-compact { width: 69px; min-width: 69px; height: 20px; gap: 3px; padding: 1px 6px 1px 2px; font-size: 7.5px; }
.pepbs-badge-icon { width: 17px; height: 17px; display: grid; flex: 0 0 auto; place-items: center; border-radius: 50%; color: rgba(255,255,255,.95); background: rgba(11,13,21,.2); }
.pepbs-badge-icon svg { width: 13px; height: 13px; fill: currentColor; overflow: visible; }
.pepbs-type-logo.is-compact .pepbs-badge-icon { width: 14px; height: 14px; }
.pepbs-type-logo.is-compact .pepbs-badge-icon svg { width: 10px; height: 10px; }
.pepbs-badge-copy { min-width: 0; align-self: stretch; display: grid; flex: 1 1 auto; place-items: center; padding-top: 1px; overflow: hidden; text-align: center; text-overflow: ellipsis; white-space: nowrap; line-height: 1; }
.pepbs-type-logo .pepbs-badge-copy { overflow: visible; text-overflow: clip; }
.pepbs-category-logo { min-width: 82px; }
.pepbs-category-logo.is-compact { width: 20px; min-width: 20px; height: 20px; padding: 1px; border-radius: 6px; }
.pepbs-category-logo.is-compact .pepbs-badge-copy { display: none; }
.pepbs-category-logo.is-compact .pepbs-badge-icon { width: 16px; height: 16px; background: transparent; }
.pepbs-category-logo.is-compact .pepbs-badge-icon svg { width: 13px; height: 13px; }
.pepbs-category-picker { position: relative; width: 100%; }
.pepbs-category-summary { height: 32px; display: flex; align-items: center; padding: 2px 30px 2px 7px; border: 1px solid var(--border); border-radius: 6px; background: var(--input-bg, var(--bg-secondary)); cursor: pointer; list-style: none; }
.pepbs-category-summary::-webkit-details-marker { display: none; }
.pepbs-category-menu { position: absolute; z-index: 65; top: 35px; left: 0; display: flex; gap: 4px; padding: 5px; border: 1px solid var(--border); border-radius: 7px; background: var(--bg-secondary); box-shadow: 0 12px 30px rgba(0,0,0,.25); }
.pepbs-category-picker.opens-up .pepbs-category-menu { top: auto; bottom: 35px; }
.pepbs-category-option { width: 94px; height: 38px; display: grid; place-items: center; border: 0; border-radius: 5px; background: transparent; cursor: pointer; }
.pepbs-category-option:hover, .pepbs-category-option.is-active { background: var(--bg-tertiary); }
.pepbs-ref-picker { position: relative; min-width: 0; }
.pepbs-ref-picker > .pepbs-input { padding-right: 30px; cursor: pointer; }
.pepbs-ref-value { display: block; overflow: hidden; text-align: left; text-overflow: ellipsis; white-space: nowrap; user-select: none; }
.pepbs-ref-value.is-placeholder { color: var(--text-tertiary); }
.pepbs-ref-picker.has-move-visual > .pepbs-input { padding-right: 145px; }
.pepbs-ref-picker.has-pokemon-visual > .pepbs-input { padding-right: 80px; }
.pepbs-ref-toggle { position: absolute; z-index: 2; top: 1px; right: 1px; width: 28px; height: 30px; border: 0; border-left: 1px solid var(--border); border-radius: 0 5px 5px 0; color: var(--text-tertiary); background: var(--input-bg, var(--bg-secondary)); cursor: pointer; }
.pepbs-ref-toggle::after { content: ""; position: absolute; left: 10px; top: 10px; width: 6px; height: 6px; border-right: 1.5px solid currentColor; border-bottom: 1.5px solid currentColor; transform: rotate(45deg); transition: transform 140ms ease, top 140ms ease; }
.pepbs-ref-toggle[aria-expanded="true"]::after { top: 13px; transform: rotate(225deg); }
.pepbs-ref-toggle:hover { color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-ref-current { position: absolute; z-index: 1; top: 5px; right: 34px; height: 22px; display: flex; align-items: center; gap: 4px; pointer-events: none; }
.pepbs-ref-picker.has-pokemon-visual .pepbs-ref-current { top: 1px; width: 40px; height: 30px; justify-content: center; border-left: 1px solid var(--border); background: color-mix(in srgb, var(--bg-tertiary) 72%, transparent); }
.pepbs-ref-pokemon-icon { width: 30px; height: 30px; display: block; overflow: hidden; }
.pepbs-ref-pokemon-icon img { height: 30px; max-width: none; display: block; image-rendering: pixelated; }
.pepbs-ref-menu { position: absolute; z-index: 35; top: 35px; left: 0; width: max(100%, 340px); max-height: 310px; overflow: hidden; padding: 5px; border: 1px solid var(--border); border-radius: 7px; background: var(--bg-secondary); box-shadow: 0 12px 30px rgba(0,0,0,.25); }
.pepbs-ref-picker.opens-up .pepbs-ref-menu { top: auto; bottom: 35px; }
.pepbs-ref-menu[hidden] { display: none; }
.pepbs-ref-search { width: 100%; height: 30px; margin-bottom: 4px; padding: 5px 8px; border: 1px solid var(--border); border-radius: 5px; color: var(--text-primary); background: var(--input-bg,var(--bg-primary)); font: inherit; font-size: 10px; }
.pepbs-ref-options { max-height: 266px; overflow-y: auto; overscroll-behavior: contain; }
.pepbs-ref-option { width: 100%; min-height: 35px; display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 5px 7px; border: 0; border-radius: 5px; color: var(--text-primary); background: transparent; cursor: pointer; text-align: left; }
.pepbs-ref-option:hover, .pepbs-ref-option.is-active { background: var(--bg-tertiary); }
.pepbs-ref-option.is-empty { min-height: 30px; color: var(--text-tertiary); }
.pepbs-ref-group-label { margin: 5px 5px 2px; padding: 7px 2px 4px; border-top: 1px solid var(--border); color: var(--text-tertiary); font-size: 8.5px; font-weight: 750; letter-spacing: .07em; text-transform: uppercase; }
.pepbs-ref-copy { min-width: 0; display: flex; flex-direction: column; }
.pepbs-ref-copy strong { overflow: hidden; font-size: 11px; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-ref-copy small { overflow: hidden; color: var(--text-tertiary); font: 8.5px ui-monospace, SFMono-Regular, Consolas, monospace; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-ref-empty { padding: 9px; color: var(--text-tertiary); font-size: 10px; }
.pepbs-move-visuals { display: flex; flex: 0 0 auto; align-items: center; gap: 5px; }
.pepbs-field.has-error:not(.pepbs-complex) .pepbs-input, .pepbs-field.has-error:not(.pepbs-complex) .pepbs-textarea, .pepbs-field.has-error:not(.pepbs-complex) .pepbs-dropdown-trigger, .pepbs-input.is-invalid, .pepbs-ref-picker.is-invalid > .pepbs-input { border-color: var(--pepbs-danger); }
.pepbs-field-error { margin-top: 4px; color: var(--pepbs-danger); font-size: 9.5px; }
.pepbs-complex { grid-column: 1 / -1; border-top: 1px solid var(--border); padding-top: 13px; }
.pepbs-rows { display: flex; flex-direction: column; gap: 5px; }
.pepbs-level-moves-actions { display: flex; align-items: center; justify-content: flex-start; gap: 7px; margin-top: 9px; }
.pepbs-level-moves-actions .pepbs-add { margin-top: 0; }
.pepbs-row { position: relative; display: grid; grid-template-columns: minmax(0,1fr) auto; gap: 5px; align-items: center; transition: transform 160ms ease-in-out, background-color 120ms ease, box-shadow 120ms ease; }
.pepbs-row.pair { grid-template-columns: 90px minmax(0,1fr) auto; }
.pepbs-row.triplet { grid-template-columns: minmax(170px,1.25fr) minmax(135px,.9fr) minmax(115px,1fr) auto; }
.pepbs-evolution-row { min-width: 470px; }
.pepbs-evolution-row > .is-dependency-disabled { filter: saturate(.45); }
.pepbs-row-actions { display: flex; gap: 2px; }
.pepbs-mini { width: 25px; height: 27px; display: grid; place-items: center; padding: 0; border: 1px solid transparent; border-radius: 4px; color: var(--text-tertiary); background: transparent; cursor: pointer; }
.pepbs-mini:hover { color: var(--text-primary); border-color: var(--border); background: var(--bg-tertiary); }
.pepbs-drag-grip { cursor: grab; touch-action: none; user-select: none; }
.pepbs-drag-grip:active, .pepbs-drag-grip.is-dragging { cursor: grabbing; color: var(--pepbs-accent); border-color: color-mix(in srgb, var(--pepbs-accent) 55%, var(--border)); background: color-mix(in srgb, var(--pepbs-accent) 9%, var(--bg-tertiary)); }
.pepbs-drag-grip:disabled { opacity: .34; cursor: default; }
.pepbs-grip-dots { width: 8px; height: 12px; display: grid; grid-template-columns: repeat(2,2px); grid-template-rows: repeat(3,2px); place-content: space-between; }
.pepbs-grip-dots i { width: 2px; height: 2px; border-radius: 50%; background: currentColor; }
[data-reorder-row].is-reorder-source { z-index: 2; border-radius: 5px; transform: translateY(var(--pepbs-reorder-drag-y, 0)); transition: none !important; box-shadow: 0 0 0 1px color-mix(in srgb, var(--pepbs-accent) 62%, transparent); background: color-mix(in srgb, var(--pepbs-accent) 5%, var(--bg-secondary)); }
[data-reorder-row].is-reorder-shifted { transform: translateY(var(--pepbs-reorder-y)); transition: transform 110ms ease-out !important; }
.pepbs-team-card { transition: transform 160ms ease-in-out, background-color 120ms ease, box-shadow 120ms ease; }
@media (prefers-reduced-motion: reduce) {
  .pepbs-row, .pepbs-team-card { transition-duration: 0ms; }
}
.pepbs-add { margin-top: 7px; }
.pepbs-stats { display: grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap: 8px; }
.pepbs-stat { display: grid; grid-template-columns: 56px minmax(0,1fr); align-items: center; gap: 6px; }
.pepbs-stat label { color: var(--text-tertiary); font-size: 9px; }
.pepbs-flags { display: grid; grid-template-columns: repeat(3,minmax(0,1fr)); gap: 4px 9px; }
.pepbs-flag { display: flex; align-items: center; gap: 6px; min-height: 27px; color: var(--text-secondary); font-size: 10px; }
.pepbs-team { display: flex; flex-direction: column; gap: 10px; }
.pepbs-team-card { padding: 11px; border: 1px solid var(--border); border-radius: 8px; background: var(--bg-secondary); }
.pepbs-team-head { display: grid; grid-template-columns: 48px minmax(0,1fr) auto; align-items: end; gap: 10px; }
.pepbs-team-icon { width: 48px; height: 48px; display: grid; place-items: center; overflow: hidden; border: 1px solid var(--border); border-radius: 8px; color: var(--text-tertiary); background: var(--bg-tertiary); font-weight: 700; }
.pepbs-team-icon img { height: 48px; max-width: none; justify-self: start; image-rendering: pixelated; }
.pepbs-team-identity { display: grid; grid-template-columns: minmax(0,1fr) 80px; gap: 8px; }
.pepbs-team-field { min-width: 0; display: flex; flex-direction: column; gap: 4px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-team-moves { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 7px; margin-top: 10px; }
.pepbs-team-advanced { margin-top: 9px; border-top: 1px solid var(--border); }
.pepbs-team-advanced > summary { padding: 9px 1px 2px; color: var(--text-secondary); cursor: pointer; font-size: 10px; font-weight: 650; }
.pepbs-team-grid { display: grid; grid-template-columns: repeat(3,minmax(0,1fr)); gap: 8px; padding-top: 10px; }
.pepbs-team-toggles { display: flex; gap: 18px; margin-top: 11px; }
.pepbs-team-toggles label { display: flex; align-items: center; gap: 6px; color: var(--text-secondary); font-size: 10px; }
.pepbs-team-stat-block { margin-top: 11px; }
.pepbs-team-stat-block > strong { display: block; margin-bottom: 6px; color: var(--text-secondary); font-size: 10px; }
.pepbs-team-stats { display: grid; grid-template-columns: repeat(6,minmax(0,1fr)); gap: 5px; }
.pepbs-team-count { margin-left: 9px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-team-preview { min-height: 110px; flex-wrap: wrap; }
.pepbs-trainer-art { max-width: 112px; max-height: 150px; image-rendering: pixelated; object-fit: contain; }
.pepbs-party-icons { max-width: 152px; display: grid; grid-template-columns: repeat(3,48px); gap: 5px; }
.pepbs-inspector { overflow: auto; border-left: 1px solid var(--border); background: var(--bg-secondary); }
.pepbs-preview { min-height: 235px; padding: 17px; border-bottom: 1px solid var(--border); }
.pepbs-preview-label, .pepbs-issues-label { margin-bottom: 11px; color: var(--text-tertiary); font-size: 9.5px; font-weight: 750; letter-spacing: .08em; text-transform: uppercase; }
.pepbs-art { min-height: 128px; display: flex; align-items: center; justify-content: center; gap: 8px; margin-bottom: 10px; }
.pepbs-art img { image-rendering: pixelated; object-fit: contain; }
.pepbs-icon-crop { width: 64px; height: 64px; overflow: hidden; flex: 0 0 auto; }
.pepbs-icon-crop img { height: 64px; max-width: none; }
.pepbs-item-art { max-width: 80px; max-height: 80px; transform: scale(1.5); }
.pepbs-art-placeholder { width: 82px; height: 82px; display: grid; place-items: center; border: 1px dashed var(--border); border-radius: 18px; color: var(--text-tertiary); }
.pepbs-art-placeholder .pepbs-domain-icon { width: 32px; height: 32px; }
.pepbs-preview-name { font-size: 15px; font-weight: 720; letter-spacing: -.015em; }
.pepbs-preview-id { margin-top: 2px; color: var(--text-tertiary); font: 9.5px ui-monospace, SFMono-Regular, Consolas, monospace; }
.pepbs-preview-description { margin: 10px 0 0; color: var(--text-secondary); font-size: 10.5px; }
.pepbs-type-row { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 9px; }
.pepbs-summary { display: grid; grid-template-columns: 1fr 1fr; gap: 1px; margin-top: 12px; background: var(--border); }
.pepbs-summary div { padding: 7px; background: var(--bg-secondary); }
.pepbs-summary span { display: block; color: var(--text-tertiary); font-size: 8.5px; text-transform: uppercase; }
.pepbs-summary strong { display: block; margin-top: 2px; font-size: 11px; }
.pepbs-issues { padding: 15px; }
.pepbs-issue { margin-bottom: 7px; padding-left: 9px; border-left: 2px solid var(--pepbs-warning); color: var(--text-secondary); font-size: 10px; }
.pepbs-issue.error { border-left-color: var(--pepbs-danger); }
.pepbs-issue strong { display: block; margin-bottom: 1px; color: var(--text-primary); font-size: 9px; }
.pepbs-ok { width: 32px; height: 32px; display: grid; place-items: center; border-radius: 50%; color: #61b77a; background: color-mix(in srgb, #61b77a 12%, transparent); font-size: 17px; font-weight: 800; }
.pepbs-footer { min-height: 28px; display: flex; align-items: center; gap: 8px; padding: 4px 10px; border-top: 1px solid var(--border); color: var(--text-tertiary); background: var(--bg-secondary); font-size: 9.5px; }
.pepbs-footer .error { color: var(--pepbs-danger); }
.pepbs-footer .warning { color: var(--pepbs-warning); }
.pepbs-footer > span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-footer-ok { color: #61b77a; }
.pepbs-notices { position: absolute; z-index: 120; right: 14px; bottom: 38px; width: min(380px, calc(100% - 28px)); display: flex; flex-direction: column; align-items: stretch; gap: 7px; pointer-events: none; }
.pepbs-notice { min-height: 44px; display: grid; grid-template-columns: 22px minmax(0,1fr) 24px; align-items: center; gap: 8px; padding: 8px 8px 8px 10px; border: 1px solid color-mix(in srgb, var(--pepbs-accent) 36%, var(--border)); border-radius: 7px; color: var(--text-primary); background: color-mix(in srgb, var(--bg-secondary) 96%, transparent); box-shadow: 0 14px 34px rgba(0,0,0,.3); pointer-events: auto; animation: pepbs-notice-in 180ms ease-out; }
.pepbs-notice.is-error { border-color: color-mix(in srgb, var(--pepbs-danger) 48%, var(--border)); }
.pepbs-notice-mark { width: 20px; height: 20px; display: grid; place-items: center; border-radius: 50%; color: #61b77a; background: color-mix(in srgb, #61b77a 13%, transparent); font-size: 11px; font-weight: 800; }
.pepbs-notice.is-error .pepbs-notice-mark { color: var(--pepbs-danger); background: color-mix(in srgb, var(--pepbs-danger) 12%, transparent); }
.pepbs-notice-copy { font-size: 10.5px; line-height: 1.4; }
.pepbs-notice-close { width: 24px; height: 24px; padding: 0; border: 0; border-radius: 4px; color: var(--text-tertiary); background: transparent; cursor: pointer; font: inherit; font-size: 16px; line-height: 1; }
.pepbs-notice-close:hover { color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-notice.is-leaving { opacity: 0; transform: translateY(4px); transition: opacity 140ms ease-in, transform 140ms ease-in; }
@keyframes pepbs-notice-in { from { opacity: 0; transform: translateY(7px); } to { opacity: 1; transform: translateY(0); } }
.pepbs-dialogs:empty { display: none; }
.pepbs-dialog-backdrop { position: absolute; z-index: 150; inset: 0; display: grid; place-items: center; padding: 18px; background: rgba(7,9,16,.58); backdrop-filter: blur(2px); animation: pepbs-dialog-backdrop-in 150ms ease-out; }
.pepbs-dialog { width: min(440px, 100%); overflow: hidden; border: 1px solid var(--border); border-radius: 9px; color: var(--text-primary); background: var(--bg-secondary); box-shadow: 0 22px 60px rgba(0,0,0,.42); animation: pepbs-dialog-in 180ms ease-out; }
.pepbs-dialog-head { min-height: 66px; display: grid; grid-template-columns: 28px minmax(0,1fr); align-items: center; gap: 10px; padding: 13px 16px; border-bottom: 1px solid var(--border); }
.pepbs-dialog-head .pepbs-domain-icon { width: 22px; height: 22px; color: var(--pepbs-accent); }
.pepbs-dialog-head h2 { margin: 0; font-size: 14px; letter-spacing: -.01em; }
.pepbs-dialog-head p { margin: 3px 0 0; color: var(--text-tertiary); font-size: 9.5px; }
.pepbs-dialog-fields { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; padding: 16px; }
.pepbs-dialog-fields label { min-width: 0; display: flex; flex-direction: column; gap: 5px; color: var(--text-secondary); font-size: 10px; font-weight: 650; }
.pepbs-dialog-fields .pepbs-dialog-field-wide { grid-column: 1 / -1; }
.pepbs-dialog-error { min-height: 15px; grid-column: 1/-1; color: var(--pepbs-danger); font-size: 9.5px; }
.pepbs-dialog-actions { display: flex; justify-content: flex-end; gap: 7px; padding: 10px 16px; border-top: 1px solid var(--border); }
@keyframes pepbs-dialog-backdrop-in { from { opacity: 0; } to { opacity: 1; } }
@keyframes pepbs-dialog-in { from { opacity: 0; transform: translateY(6px) scale(.99); } to { opacity: 1; transform: translateY(0) scale(1); } }
.pepbs-loading { height: 100%; display: grid; place-items: center; color: var(--text-secondary); }
.pepbs-ebdx-badge { color: #91adff; border-color: color-mix(in srgb, #7897ff 50%, var(--border)); background: color-mix(in srgb, #7897ff 9%, var(--bg-secondary)); }
.pepbs-ebdx-workspace { min-height: 320px; display: grid; grid-template-columns: minmax(0, 1fr) minmax(210px, 242px); gap: 16px; align-items: stretch; overflow: hidden; padding: 14px; }
.pepbs-ebdx-stage-shell { min-width: 0; min-height: 0; display: flex; align-items: center; justify-content: center; overflow: hidden; }
.pepbs-ebdx-stage { position: relative; flex: 0 0 auto; max-width: 100%; max-height: 100%; overflow: hidden; border: 1px solid color-mix(in srgb, var(--border) 82%, #718aa1); border-radius: 8px; background: #182b3d; box-shadow: 0 12px 32px rgba(0,0,0,.18); }
.pepbs-ebdx-canvas { width: 100%; height: 100%; display: block; cursor: grab; touch-action: none; image-rendering: pixelated; }
.pepbs-ebdx-canvas:active { cursor: grabbing; }
.pepbs-ebdx-controls { min-width: 0; min-height: 0; overflow-y: auto; padding: 2px 2px 2px 16px; border-left: 1px solid var(--border); scrollbar-width: thin; }
.pepbs-ebdx-eyebrow { margin-bottom: 5px; color: #8ca6ff; font-size: 9px; font-weight: 760; letter-spacing: .09em; text-transform: uppercase; }
.pepbs-ebdx-controls h3 { margin: 0; font-size: 16px; letter-spacing: -.015em; }
.pepbs-ebdx-controls > p { margin: 6px 0 11px; color: var(--text-secondary); font-size: 9.5px; }
.pepbs-ebdx-history { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; margin: 0 0 12px; }
.pepbs-ebdx-history-btn { min-width: 0; display: inline-flex; align-items: center; justify-content: center; gap: 5px; padding-inline: 8px; }
.pepbs-ebdx-history-btn > span:first-child { color: #91adff; font-size: 14px; line-height: 1; }
.pepbs-ebdx-history-btn:disabled { opacity: .42; cursor: default; }
.pepbs-ebdx-history-btn:disabled > span:first-child { color: var(--text-tertiary); }
.pepbs-ebdx-side-tabs { display: grid; grid-template-columns: 1fr 1fr; gap: 3px; margin-bottom: 11px; padding: 3px; border-radius: 6px; background: var(--bg-tertiary); }
.pepbs-ebdx-side-tabs button { min-height: 31px; border: 0; border-radius: 4px; color: var(--text-secondary); background: transparent; cursor: pointer; font: inherit; font-size: 10px; }
.pepbs-ebdx-side-tabs button:hover { color: var(--text-primary); }
.pepbs-ebdx-side-tabs button.is-active { color: var(--text-primary); background: var(--bg-primary); box-shadow: 0 1px 3px rgba(0,0,0,.14); }
.pepbs-ebdx-coordinate-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 9px; }
.pepbs-ebdx-coordinate { display: flex; flex-direction: column; gap: 4px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-ebdx-coordinate .pepbs-input { font-variant-numeric: tabular-nums; }
.pepbs-ebdx-altitude { display: grid; gap: 7px; margin-top: 12px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-ebdx-altitude-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.pepbs-ebdx-altitude-value { min-width: 34px; padding: 2px 7px; border: 1px solid var(--border); border-radius: 999px; color: var(--text-primary); background: var(--bg-tertiary); font: 700 10px/1.3 ui-monospace,monospace; text-align: center; font-variant-numeric: tabular-nums; }
.pepbs-ebdx-altitude-control { display: grid; grid-template-columns: minmax(0,1fr) 30px; align-items: center; gap: 7px; }
.pepbs-ebdx-altitude-zero { width: 30px; min-width: 30px; padding-inline: 0; font-variant-numeric: tabular-nums; }
.pepbs-ebdx-range { width: 100%; height: 18px; margin: 0; appearance: none; background: transparent; cursor: pointer; }
.pepbs-ebdx-range::-webkit-slider-runnable-track { height: 4px; border-radius: 4px; background: color-mix(in srgb, var(--pepbs-accent) 32%, var(--bg-tertiary)); }
.pepbs-ebdx-range::-webkit-slider-thumb { width: 15px; height: 15px; margin-top: -5.5px; appearance: none; border: 2px solid var(--bg-primary); border-radius: 50%; background: var(--pepbs-accent); box-shadow: 0 0 0 1px color-mix(in srgb, var(--pepbs-accent) 65%, var(--border)); }
.pepbs-ebdx-actions { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
.pepbs-root.is-townmap .pepbs-body { grid-template-columns: 176px minmax(230px,270px) minmax(0,1fr); }
.pepbs-root.is-townmap .pepbs-inspector { display: none; }
.pepbs-world-form { min-height: 100%; padding-bottom: 28px; }
.pepbs-world-record-head { min-height: 76px; display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; padding: 14px 18px; border-bottom: 1px solid var(--border); background: var(--bg-primary); }
.pepbs-world-record-head h2 { margin: 0; font-size: 18px; line-height: 1.2; }
.pepbs-world-record-head code { display: block; margin-top: 4px; color: var(--text-tertiary); font-size: 10px; }
.pepbs-world-head-fields { min-width: 280px; display: grid; grid-template-columns: minmax(150px,1fr) 80px; gap: 8px; }
.pepbs-world-head-fields.is-version-only { min-width: 80px; grid-template-columns: 80px; }
.pepbs-world-head-actions { display: flex; flex: 0 0 auto; align-items: center; justify-content: flex-end; gap: 6px; }
.pepbs-world-head-actions .pepbs-btn { min-height: 32px; }
.pepbs-world-grid { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 14px 18px; padding: 20px; }
.pepbs-world-field { min-width: 0; display: flex; flex-direction: column; gap: 6px; color: var(--text-secondary); font-size: 10px; font-weight: 650; }
.pepbs-world-field.is-wide { grid-column: 1/-1; }
.pepbs-world-field > .pepbs-input, .pepbs-world-field > .pepbs-dropdown { width: 100%; }
.pepbs-switch { flex: 0 0 auto; width: 34px; height: 18px; margin: 0; padding: 0; appearance: none; border: 1px solid var(--border); border-radius: 99px; background: var(--bg-tertiary); cursor: pointer; transition: background-color 140ms ease, border-color 140ms ease; }
.pepbs-switch::after { content: ""; display: block; width: 12px; height: 12px; margin: 2px; border-radius: 50%; background: var(--text-tertiary); transition: transform 140ms ease, background-color 140ms ease; }
.pepbs-switch:checked { border-color: var(--pepbs-accent); background: color-mix(in srgb,var(--pepbs-accent) 35%,var(--bg-tertiary)); }
.pepbs-switch:checked::after { transform: translateX(16px); background: var(--pepbs-accent); }
.pepbs-switch:hover { border-color: color-mix(in srgb,var(--pepbs-accent) 55%,var(--border)); }
.pepbs-world-field > .pepbs-switch { margin: 6px 0; }
.pepbs-world-coordinate { display: grid; grid-template-columns: minmax(120px,1fr) 72px 72px; gap: 6px; }
.pepbs-world-weather { grid-template-columns: minmax(150px,1fr) 72px; }
.pepbs-world-coordinate > * { min-width: 0; width: 100%; }
.pepbs-metadata-overview { display: grid; grid-template-columns: minmax(0,1fr); gap: 20px; padding: 18px 20px 0; }
.pepbs-metadata-overview.is-global { grid-template-columns: minmax(0,1fr); }
.pepbs-metadata-section { min-width: 0; margin: 18px 20px 0; padding-top: 16px; border-top: 1px solid var(--border); }
.pepbs-metadata-overview > .pepbs-metadata-section { margin: 0; padding-top: 0; border-top: 0; }
.pepbs-metadata-section > h3 { margin: 0 0 12px; color: var(--text-primary); font-size: 11px; font-weight: 720; }
.pepbs-metadata-grid { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 13px 18px; }
.pepbs-metadata-grid.is-stack { grid-template-columns: minmax(0,1fr); }
.pepbs-metadata-grid.is-switches { grid-template-columns: repeat(2,minmax(0,1fr)); gap: 8px 18px; align-content: start; }
.pepbs-metadata-grid.is-switches .pepbs-world-field { min-height: 53px; justify-content: space-between; padding: 1px 0 7px; border-bottom: 1px solid color-mix(in srgb,var(--border) 65%,transparent); }
.pepbs-metadata-grid.is-switches .pepbs-world-field > .pepbs-switch { margin: 0; }
.pepbs-metadata-grid.is-secondary { margin-top: 16px; padding-top: 14px; border-top: 1px solid color-mix(in srgb,var(--border) 68%,transparent); }
.pepbs-world-player { margin: 0 20px 16px; border-top: 1px solid var(--border); }
.pepbs-world-player-head { min-height: 60px; display: flex; align-items: center; justify-content: space-between; gap: 16px; padding-top: 14px; }
.pepbs-world-player-preview { width: 64px; height: 48px; overflow: hidden; display: grid; place-items: center; }
.pepbs-world-player-frame { display: block; max-width: 64px; max-height: 48px; image-rendering: pixelated; }
.pepbs-world-player .pepbs-world-grid { padding: 10px 0 2px; }
.pepbs-encounter-group { margin: 16px 20px; border-top: 1px solid var(--border); }
.pepbs-encounter-head { display: grid; grid-template-columns: minmax(150px,1fr) minmax(150px,1fr) auto; align-items: end; gap: 10px; padding: 14px 0 10px; }
.pepbs-encounter-head > .pepbs-btn { min-height: 32px; }
.pepbs-encounter-table { min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.pepbs-encounter-labels,.pepbs-encounter-row { min-width: 0; max-width: 100%; box-sizing: border-box; display: grid; grid-template-columns: minmax(54px,.42fr) minmax(150px,2fr) minmax(74px,.62fr) minmax(74px,.62fr) 54px; align-items: center; gap: 6px; }
.pepbs-encounter-labels { padding: 0 5px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-encounter-row { position: relative; padding: 4px; border-radius: 6px; background: color-mix(in srgb,var(--bg-secondary) 70%,transparent); }
.pepbs-encounter-species { min-width: 0; display: grid; grid-template-columns: 42px minmax(0,1fr); align-items: center; gap: 7px; }
.pepbs-encounter-icon { width: 40px; height: 40px; overflow: hidden; display: block; align-self: center; justify-self: center; }
.pepbs-encounter-icon img { display: block; height: 40px; max-width: none; image-rendering: pixelated; }
.pepbs-encounter-row > .pepbs-row-actions { min-width: 0; justify-self: end; }
.pepbs-encounter-actions { display: flex; align-items: center; justify-content: flex-start; gap: 7px; margin-top: 5px; }
.pepbs-encounter-actions .pepbs-add { margin-top: 0; }
.pepbs-connection-form { height: 100%; min-height: 0; display: grid; grid-template-rows: auto minmax(0,1fr); overflow: hidden; padding-bottom: 0; }
.pepbs-connection-workspace { min-width: 0; min-height: 0; display: grid; grid-template-columns: minmax(430px,1fr) clamp(280px,29%,340px); overflow: hidden; }
.pepbs-connection-canvas { min-width: 0; min-height: 0; display: grid; place-items: center; overflow: hidden; padding: 18px; }
.pepbs-connection-settings { min-width: 0; min-height: 0; overflow: auto; border-left: 1px solid var(--border); background: var(--bg-secondary); }
.pepbs-connection-settings-head { min-height: 54px; display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 11px 14px; border-bottom: 1px solid var(--border); }
.pepbs-connection-settings-head h3 { margin: 0; color: var(--text-primary); font-size: 12px; }
.pepbs-connection-settings-grid { grid-template-columns: minmax(0,1fr); gap: 12px; padding: 14px; }
.pepbs-connection-settings-grid .pepbs-world-field.is-wide { grid-column: auto; }
.pepbs-coordinate-picker-button { width: 100%; min-height: 34px; display: grid; grid-template-columns: 22px minmax(0,1fr) 18px; align-items: center; gap: 7px; padding: 6px 9px; border: 1px solid var(--border); border-radius: 6px; color: var(--text-primary); background: var(--bg-tertiary); text-align: left; cursor: pointer; }
.pepbs-coordinate-picker-button:hover { border-color: var(--pepbs-accent); background: color-mix(in srgb,var(--bg-tertiary) 86%,var(--pepbs-accent)); }
.pepbs-coordinate-picker-icon { width: 20px; height: 20px; display: grid; place-items: center; border-radius: 4px; color: var(--pepbs-accent); background: color-mix(in srgb,var(--pepbs-accent) 15%,transparent); font-size: 14px; }
.pepbs-coordinate-picker-arrow { color: var(--text-tertiary); font-size: 18px; text-align: right; }
.pepbs-map-dialog-backdrop { z-index: 190; }
.pepbs-map-dialog { width: min(980px,94vw); height: min(760px,84vh); min-height: 440px; display: grid; grid-template-rows: auto auto minmax(0,1fr) auto; overflow: hidden; border: 1px solid var(--border); border-radius: 9px; background: var(--bg-secondary); box-shadow: 0 22px 65px rgba(0,0,0,.48); }
.pepbs-map-dialog-head { min-height: 64px; display: flex; align-items: center; justify-content: space-between; gap: 18px; padding: 12px 16px; border-bottom: 1px solid var(--border); }
.pepbs-map-dialog-head h2 { margin: 0 0 3px; color: var(--text-primary); font-size: 15px; }
.pepbs-map-dialog-head p { margin: 0; color: var(--text-tertiary); font-size: 10px; }
.pepbs-dialog-close { width: 30px; height: 30px; display: grid; place-items: center; flex: 0 0 auto; padding: 0; border: 1px solid transparent; border-radius: 6px; color: var(--text-secondary); background: transparent; font-size: 19px; cursor: pointer; }
.pepbs-dialog-close:hover { border-color: var(--border); color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-map-dialog-toolbar { min-height: 50px; display: flex; align-items: center; gap: 10px; padding: 8px 16px; border-bottom: 1px solid var(--border); background: var(--bg-primary); }
.pepbs-map-dialog-toolbar > .pepbs-dropdown { width: min(320px,40%); }
.pepbs-map-dialog-coordinates { color: var(--text-secondary); font: 600 10px/1.2 ui-monospace,monospace; }
.pepbs-direction-control { display: flex; flex: 0 0 auto; align-items: center; gap: 7px; color: var(--text-tertiary); font-size: 9px; }
.pepbs-direction-buttons { display: flex; align-items: center; overflow: hidden; border: 1px solid var(--border); border-radius: 6px; background: var(--bg-secondary); }
.pepbs-direction-button { width: 30px; height: 30px; display: grid; place-items: center; padding: 0; border: 0; border-right: 1px solid var(--border); color: var(--text-secondary); background: transparent; cursor: pointer; font: 700 14px/1 var(--font-family,system-ui); transition: color 120ms ease,background-color 120ms ease; }
.pepbs-direction-button:last-child { border-right: 0; }
.pepbs-direction-button:hover { color: var(--text-primary); background: var(--bg-tertiary); }
.pepbs-direction-button.is-active { color: var(--accent-text); background: var(--pepbs-accent); }
.pepbs-direction-button:focus-visible { position: relative; z-index: 1; outline: 2px solid color-mix(in srgb,var(--pepbs-accent) 65%,transparent); outline-offset: -2px; }
.pepbs-zoom-controls,.pepbs-atlas-head-actions { display: flex; align-items: center; gap: 6px; margin-left: auto; }
.pepbs-zoom-label { min-width: 43px; color: var(--text-secondary); font: 600 9px/1 ui-monospace,monospace; text-align: center; }
.pepbs-map-picker-viewport,.pepbs-atlas-viewport { min-width: 0; min-height: 0; overflow: auto; background: #0b0d16; scrollbar-gutter: stable; cursor: crosshair; }
.pepbs-map-picker-viewport.is-panning,.pepbs-atlas-viewport.is-panning { cursor: grabbing; user-select: none; }
.pepbs-map-picker-stage,.pepbs-atlas-stage { position: relative; min-width: 100%; min-height: 100%; transform-origin: 0 0; background-color: #0b0d16; background-image: linear-gradient(rgba(255,255,255,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.045) 1px,transparent 1px); background-size: 16px 16px; }
.pepbs-map-picker-stage .pepbs-map-raster { display: block; image-rendering: pixelated; cursor: crosshair; }
.pepbs-map-cell-marker { position: absolute; z-index: 3; width: 16px; height: 16px; pointer-events: none; border: 2px solid #fff; background: rgba(101,126,255,.35); box-shadow: 0 0 0 2px rgba(23,28,52,.85),inset 0 0 0 1px rgba(101,126,255,.9); }
.pepbs-map-cell-marker.is-region { width: 16px; height: 16px; }
.pepbs-map-loading,.pepbs-map-error { position: sticky; left: 0; top: 0; min-width: 280px; min-height: 220px; display: grid; place-items: center; padding: 28px; color: var(--text-tertiary); font-size: 11px; text-align: center; }
.pepbs-map-error { color: var(--danger,#ef6b75); }
.pepbs-map-error strong { align-self: end; font-weight: 650; }
.pepbs-map-error code { align-self: start; max-width: min(620px,90vw); margin-top: 7px; color: color-mix(in srgb,var(--danger,#ef6b75) 76%,var(--text-primary)); font: 9.5px/1.45 ui-monospace,SFMono-Regular,Consolas,monospace; overflow-wrap: anywhere; }
.pepbs-region-picker-viewport img { display: block; image-rendering: pixelated; cursor: crosshair; user-select: none; }
.pepbs-map-dialog > .pepbs-dialog-actions { min-height: 56px; margin: 0; padding: 10px 16px; border-top: 1px solid var(--border); background: var(--bg-secondary); }
.pepbs-connection-preview { width: 100%; max-width: 860px; height: 100%; max-height: 620px; min-height: 320px; display: grid; grid-template-rows: auto minmax(0,1fr); overflow: hidden; border: 1px solid var(--border); border-radius: 7px; background: #0b0d16; }
.pepbs-connection-preview-head { min-height: 42px; display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 8px 12px; border-bottom: 1px solid var(--border); background: var(--bg-secondary); }
.pepbs-connection-preview-copy { min-width: 0; display: flex; align-items: baseline; gap: 9px; }
.pepbs-connection-preview-head strong { color: var(--text-primary); font-size: 11px; }
.pepbs-connection-preview-head span { color: var(--text-tertiary); font-size: 9px; }
.pepbs-connection-zoom { display: flex; flex: 0 0 auto; align-items: center; gap: 6px; margin-left: auto; }
.pepbs-connection-viewport { min-width: 0; min-height: 0; overflow: auto; padding: 0; scrollbar-color: var(--border) #0b0d16; cursor: grab; }
.pepbs-connection-viewport::-webkit-scrollbar-corner,.pepbs-connection-viewport::-webkit-resizer { background: #0b0d16; }
.pepbs-connection-viewport.is-panning { cursor: grabbing; user-select: none; }
.pepbs-atlas-stage { min-width: 1px; min-height: 1px; background-size: 32px 32px; }
.pepbs-atlas-links { position: absolute; z-index: 0; inset: 0; pointer-events: none; }
.pepbs-atlas-map { position: absolute; z-index: 1; display: block; padding: 0; overflow: visible; border: 0; appearance: none; color: inherit; background: transparent; cursor: pointer; }
.pepbs-atlas-map.is-focused { z-index: 2; }
.pepbs-atlas-map.is-focused-a { --pepbs-atlas-highlight: #5d91ff; z-index: 5; }
.pepbs-atlas-map.is-focused-b { --pepbs-atlas-highlight: #f0a65b; z-index: 5; }
.pepbs-atlas-corners.is-focused-a { --pepbs-atlas-highlight: #5d91ff; }
.pepbs-atlas-corners.is-focused-b { --pepbs-atlas-highlight: #f0a65b; }
.pepbs-atlas-map.is-filtered { z-index: 4; }
.pepbs-atlas-map canvas { display: block; image-rendering: pixelated; transition: filter 130ms ease-out, box-shadow 130ms ease-out; }
.pepbs-atlas-map:hover canvas { filter: brightness(1.06); }
.pepbs-atlas-map:active canvas { filter: brightness(.92); }
.pepbs-atlas-map:focus-visible { z-index: 3; outline: none; }
.pepbs-atlas-map:focus-visible canvas,.pepbs-atlas-map.is-filtered canvas { box-shadow: none; }
.pepbs-atlas-map:focus-visible::after { content: ""; position: absolute; z-index: 2; inset: -6px; pointer-events: none; background: linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 0 0/16px 3px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 0 0/3px 16px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 100% 0/16px 3px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 100% 0/3px 16px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 0 100%/16px 3px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 0 100%/3px 16px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 100% 100%/16px 3px no-repeat,linear-gradient(var(--pepbs-accent),var(--pepbs-accent)) 100% 100%/3px 16px no-repeat; filter: drop-shadow(0 0 3px color-mix(in srgb,var(--pepbs-accent) 85%,transparent)) drop-shadow(0 0 2px rgba(8,11,22,.95)); }
.pepbs-atlas-corners { position: absolute; z-index: 10; pointer-events: none; background: linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 0 0/16px 3px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 0 0/3px 16px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 100% 0/16px 3px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 100% 0/3px 16px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 0 100%/16px 3px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 0 100%/3px 16px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 100% 100%/16px 3px no-repeat,linear-gradient(var(--pepbs-atlas-highlight,var(--pepbs-accent)),var(--pepbs-atlas-highlight,var(--pepbs-accent))) 100% 100%/3px 16px no-repeat; filter: drop-shadow(0 0 3px color-mix(in srgb,var(--pepbs-atlas-highlight,var(--pepbs-accent)) 85%,transparent)) drop-shadow(0 0 2px rgba(8,11,22,.95)); }
.pepbs-atlas-map.is-filtered span { color: #fff; background: color-mix(in srgb,var(--pepbs-accent) 68%,rgba(8,11,22,.9)); box-shadow: 0 2px 8px rgba(0,0,0,.36); }
.pepbs-atlas-map span { position: absolute; z-index: 1; left: 50%; top: 50%; padding: 3px 6px; border-radius: 4px; color: rgba(255,255,255,.84); background: rgba(8,11,22,.4); box-shadow: 0 1px 4px rgba(0,0,0,.12); font: 700 8px/1.15 var(--font-family,system-ui); white-space: nowrap; pointer-events: none; transform: translate(-50%,-50%); transition: color 130ms ease-out, background-color 130ms ease-out, box-shadow 130ms ease-out; }
.pepbs-atlas-map:hover span { color: #fff; background: rgba(8,11,22,.82); box-shadow: 0 2px 7px rgba(0,0,0,.32); }
.pepbs-connection-filter { width: 100%; min-width: 0; min-height: 30px; display: flex; align-items: center; gap: 5px; margin: 8px 0 0; padding: 5px 7px; border: 1px solid color-mix(in srgb,var(--pepbs-accent) 44%,var(--border)); border-radius: 6px; color: var(--text-secondary); background: color-mix(in srgb,var(--pepbs-accent) 9%,var(--bg-tertiary)); font: inherit; text-align: left; cursor: pointer; transition: border-color 130ms ease-out,background-color 130ms ease-out; }
.pepbs-connection-filter:hover { border-color: color-mix(in srgb,var(--pepbs-accent) 70%,var(--border)); background: color-mix(in srgb,var(--pepbs-accent) 14%,var(--bg-tertiary)); }
.pepbs-connection-filter:focus-visible { outline: 2px solid color-mix(in srgb,var(--pepbs-accent) 65%,transparent); outline-offset: 2px; }
.pepbs-connection-filter-label { flex: 0 0 auto; color: var(--text-tertiary); font-size: 9px; }
.pepbs-connection-filter strong { min-width: 0; overflow: hidden; color: var(--text-primary); font-size: 10px; text-overflow: ellipsis; white-space: nowrap; }
.pepbs-connection-filter-close { flex: 0 0 auto; margin-left: auto; color: var(--text-tertiary); font-size: 14px; line-height: 1; }
.pepbs-townmap-workspace { height: 100%; min-height: 0; display: grid; grid-template-columns: minmax(340px,1fr) clamp(280px,31%,320px); overflow: hidden; }
.pepbs-townmap-stage { min-width: 0; min-height: 0; overflow: auto; display: grid; place-items: start; padding: 18px; background: var(--canvas-bg,var(--bg-primary)); }
.pepbs-townmap-map { position: relative; min-width: 320px; min-height: 240px; overflow: hidden; background: var(--bg-secondary); }
.pepbs-townmap-map img { display: block; image-rendering: pixelated; user-select: none; }
.pepbs-townmap-overlay { position: absolute; inset: 0; background-image: linear-gradient(to right,rgba(255,255,255,.13) 1px,transparent 1px),linear-gradient(to bottom,rgba(255,255,255,.13) 1px,transparent 1px); background-size: 16px 16px; cursor: crosshair; }
.pepbs-townmap-point { position: absolute; width: 16px; height: 16px; padding: 0; border: 1px solid rgba(255,255,255,.95); background: rgba(65,192,226,.28); cursor: grab; }
.pepbs-townmap-point.is-active { z-index: 2; border: 2px solid var(--pepbs-accent); background: rgba(255,255,255,.6); box-shadow: 0 0 0 2px rgba(0,0,0,.35); }
.pepbs-townmap-properties { min-width: 0; overflow-y: auto; padding: 0 14px 16px; border-left: 1px solid var(--border); background: var(--bg-secondary); scrollbar-gutter: stable; }
.pepbs-townmap-properties > * { margin-bottom: 11px; }
.pepbs-townmap-properties-head { position: sticky; z-index: 4; top: 0; min-height: 52px; display: flex; align-items: center; justify-content: space-between; gap: 8px; margin: 0 -14px 12px!important; padding: 9px 14px; border-bottom: 1px solid var(--border); background: color-mix(in srgb,var(--bg-secondary) 96%,transparent); backdrop-filter: blur(8px); }
.pepbs-townmap-properties-head strong { font-size: 12px; }
.pepbs-townmap-region-grid { display: grid; grid-template-columns: 80px minmax(0,1fr); gap: 8px; margin-bottom: 11px; }
.pepbs-townmap-region-grid .pepbs-world-field { margin: 0; }
.pepbs-townmap-properties .pepbs-ref-picker { width: 100%; }
.pepbs-townmap-properties .pepbs-ref-menu { width: 100%; min-width: 0; }
.pepbs-world-divider { height: 1px; margin: 18px 0!important; background: var(--border); }
.pepbs-world-subheading { display: block; color: var(--text-primary); font-size: 11px; }
.pepbs-world-icon-grid { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 16px; }
.pepbs-metadata-map-preview { width: 100%; min-height: 120px; max-height: 210px; display: grid; place-items: center; overflow: auto; margin-top: 16px; border: 1px solid var(--border); border-radius: 6px; background-color: #0b0d16; background-image: linear-gradient(rgba(255,255,255,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.045) 1px,transparent 1px); background-size: 12px 12px; }
.pepbs-metadata-map-preview canvas { display: block; max-width: 100%; image-rendering: pixelated; }
.pepbs-metadata-map-preview .pepbs-map-loading,.pepbs-metadata-map-preview .pepbs-map-error { min-width: 0; min-height: 120px; padding: 14px; }
@media (prefers-reduced-motion: reduce) {
  .pepbs-root * { scroll-behavior: auto !important; transition-duration: .01ms !important; animation-duration: .01ms !important; }
}
@media (max-width: 1250px) {
  .pepbs-body { grid-template-columns: 145px 250px minmax(430px,1fr); }
  .pepbs-inspector { display: none; }
  .pepbs-root.is-ebdx .pepbs-body { grid-template-columns: 140px 220px minmax(0,1fr); }
  .pepbs-ebdx-workspace { grid-template-columns: minmax(0,1fr) 210px; gap: 12px; padding: 12px; }
  .pepbs-ebdx-controls { padding-left: 12px; }
}
@media (max-width: 980px) {
  .pepbs-townmap-workspace { grid-template-columns: minmax(300px,1fr) 270px; }
  .pepbs-connection-workspace { grid-template-columns: minmax(380px,1fr) 270px; }
  .pepbs-world-record-head { flex-wrap: wrap; }
  .pepbs-world-head-fields { flex: 1 1 280px; }
  .pepbs-world-head-actions { margin-left: auto; }
}
@media (max-height: 760px) {
  .pepbs-townmap-stage { padding: 12px; }
  .pepbs-townmap-properties { padding-inline: 11px; padding-bottom: 11px; }
  .pepbs-townmap-properties-head { min-height: 44px; margin-inline: -11px!important; padding: 7px 11px; }
  .pepbs-townmap-properties > * { margin-bottom: 8px; }
  .pepbs-world-field { gap: 4px; }
}
`;
