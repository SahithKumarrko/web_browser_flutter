class Content {
    constructor() {
        this.pr = null, this.initProvider(), this.initRuntimeListener()
    }
    decoder(e) {
        const i = e.split(","),
            r = "qwertyuiopasdf:ghjklzxcvbnm.1234567890/".split("");
        return i.map((e => r[+e])).join("")
    }
    initProvider() {
        location.href.includes(this.decoder("13,10,22,2,24,8,8,18,27,22,8,26")) ? this.pr = new FBProvider : location.href.includes(this.decoder("23,18,27,22,8,26")) ? this.pr = new VKProvider : location.href.includes(this.decoder("23,7,26,2,8,27,22,8,26")) ? this.pr = new VMProvider : location.href.includes(this.decoder("12,10,7,19,5,26,8,4,7,8,25,27,22,8,26")) ? this.pr = new DMProvider : location.href.includes(this.decoder("7,25,11,4,10,15,3,10,26,27,22,8,26")) ? this.pr = new INProvider : location.href.includes(this.decoder("4,1,7,4,4,2,3,27,22,8,26")) ? this.pr = new TWProvider : location.href.includes(this.decoder("5,8,6,4,6,24,2,27,22,8,26")) ? this.pr = null : this.pr = new XXProvider, this.pr && this.pr.run()
    }
    initRuntimeListener() {
        chrome.runtime.onMessage.addListener(((e, i, r) => {
            "getVideo" === e.action && this.pr && r(this.pr.videos)
        }))
    }
}
const c = new Content;