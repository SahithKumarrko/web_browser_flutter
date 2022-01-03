package com.pichillilorenzo.flutter_inappwebview.in_app_webview;

import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Id;
import io.objectbox.annotation.Index;

@Entity
class  AdBlocker{
    @Id
    public long id=0;
    @Index
    public String host;
}