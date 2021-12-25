var vd = {};
vd.fourKDataExpTimeFree = 60*60*1000; // 1 hour
vd.fourKDataExpTimePremium = 5*60*1000; // 5 minutes
vd.fourKEmptyDataExpTime = 5*60*1000; // 5 minutes
vd.bg4KVideoCheckForAllUsers = false; // values: true, false
vd.allVideoFormats = ['mp4', "mov", "flv", "webm", "3gp", "ogg", "m4a", "mp3", "wav", "bin"];
vd.defaultVideoFormats = ['.mp4', ".mov", ".flv", ".webm", ".3gp", ".ogg", ".m4a", ".wav", ".bin"];
vd.minVideoSizes = {
    "1" :{
        bytes: 100 * 1024,
        text: "100 KB",
        id: "1"
    },
    "2" :{
        bytes: 1024 * 1024,
        text: "1 MB",
        id: "2"
    },
    "3" :{
        bytes: 2 * 1024 * 1024,
        text: "2 MB",
        id: "3"
    },
};
vd.premiumVideoFormats = [".mp3"];
vd.nonePremiumVideoFormats = ['.mp4', ".mov", ".flv", ".webm", ".3gp", ".ogg", ".m4a", ".wav", ".bin"];
vd.serverUrl = 'https://vidow.io/';
vd.serverUrl2 = 'http://vidow.me/fourk/';
vd.version = "PAID";
vd.extension = "chrome";

vd.isVideoLinkTypeValid = function (videoLink, videoTypes) {
    let isValidType = true;
    if (videoTypes.length > 0) {
        isValidType = ($.inArray(videoLink.extension + "", videoTypes) !== -1);
    }
    return isValidType;
};

vd.isVideoSizeValid = function(data, minVideoSize) {
    minVideoSize = vd.minVideoSizes[minVideoSize].bytes;
    var isValid = true;
    if(!data) {return isValid}
    var vSize = parseInt(data.filesize ? data.filesize : data.size);
    if(isNaN(vSize)) {
        return isValid;
    }
    return (vSize > minVideoSize);
};

vd.ignoreError = function () {
    if(chrome.runtime.lastError){
        console.log("error: ", chrome.runtime.lastError);
    }else{
    }
};

vd.convertToJson = function (str) {
    return typeof str === "string" ? JSON.parse(str) : str;
};

vd.getLoginToken = function (callback) {
    chrome.storage.sync.get({
        login_token: false
    }, function (items) {
        callback(items.login_token);
    })
};

vd.autoLogin = function(callback) {
    chrome.storage.sync.get({
        login_token: false
    }, function(items) {
        if(!items.login_token) {
            callback({status: 0});
            return;
        }
        $.get(vd.serverUrl+"autoLogin/"+ items.login_token, function (response) {
            response = vd.convertToJson(response);
            if(!response.status) {
                callback({status: 0});
                return;
            }
            callback({status: 1});
        });
    });
};

vd.isLoggedInAndUpgraded = function(callback) {
    chrome.storage.sync.get({
        logged_in: false,
        upgraded: 'false'
    }, function (items) {
        callback(items.logged_in && items.upgraded !== "false");
    });
};

vd.is4KDataValid = function(fourKData) {
    // console.log("Validation check", fourKData);
    var isValid = fourKData && (fourKData.title != null || (fourKData.value && fourKData.value.title != null)) && fourKData.ext !== 'unknown_video';
    // console.log(!!isValid);
    return !!isValid;
};

vd.storeFourKData = function(fourKData) {
    // console.log("Saving data");
    // console.log(fourKData);
    var url = fourKData.tabUrl ? fourKData.tabUrl : fourKData.webpage_url;
    var urlId = md5(url);
    // console.log(url, urlId);
    localStorage.setItem(urlId, JSON.stringify({
        "id": urlId,
        "url": fourKData.webpage_url,
        "value": fourKData,
        "time": new Date().getTime()
    }));
};

vd.get4KData = function (videoUrl, callback) {
    $.ajax({
        url: vd.serverUrl2 + "getinfo.php",
        type: "GET",
        contentType: "json",
        data: {videourl: encodeURIComponent(videoUrl)},
        success: function (data) {
            if(!data) {
                callback(false);
                return;
            }
            callback(data);
        },
        error: function (xhr, ajaxOptions, thrownError) {
            callback(false);
        }
    });
};


vd.is4KDataExpired = function(fourKData, callback) {
    // console.log(fourKData);
    if(!fourKData || !fourKData.time) {
        // console.log("YYYY");
        callback(true);
        return;
    }
    // console.log(new Date(fourKData.time));
    if(!vd.is4KDataValid(fourKData)) {
        callback(new Date().getTime() - fourKData.time > vd.fourKEmptyDataExpTime);
        return;
    }
    vd.isLoggedInAndUpgraded(function (bool) {
        // console.log("upgraded", bool);
       if(bool) {
           callback(new Date().getTime() - fourKData.time > vd.fourKDataExpTimePremium);
       } else {
           callback(new Date().getTime() - fourKData.time > vd.fourKDataExpTimeFree);
       }
    });

};


vd.getStoredSettings = function (callback) {
    chrome.storage.sync.get({
        videoTypes: vd.defaultVideoFormats,
        chromeCast: true,
        /*videoResolutions: [],*/
        useProxy: false,
        proxyType: '',
        proxyIP: '',
        proxyPort: '',
        proxyUser: '',
        proxyPassword: '',
        minVideoSize: '1',
        logged_in: false,
        login_token: false,
        upgraded: 'false'
    }, function (items) {
        // console.log(items);
        if(vd.version !== "FREE" && items.upgraded === "false") {
            items.videoTypes = items.videoTypes.filter(function (videoType) {
                return vd.premiumVideoFormats.indexOf(videoType) === -1;
            });
        }
        callback(items);
    });
};
