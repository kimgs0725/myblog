---
title: "프록시 패턴"
date: 2021-06-22T22:15:56+09:00
draft: true
categories:
- design pattern
tags:
- 디자인패턴
- 자바
---

팀 내에서 디자인 패턴에 대해서 스터디를 진행하고 있어서, 공부한 내용을 정리하는 차원에서 남깁니다.

> 프록시 패턴은 사용할 객체의 제어권을 위임함으로써, 객체에 대한 클라이언트의 요청을 대신 받아서 전달합니다.

프록시(Proxy)는 **대리권**을 의미하는 단어로써 프록시 패턴을 객체에 대한 제어권을 위임받는 별도의 객체를 통해 객체에 대한 클라이언트의 요청을 대리하여 수행한다. 그렇다면, 프록시는 구체적으로 어떻게 클라이언트의 요청을 대리하여 수행하고 있을까?

![](/images/Proxy_pattern_diagram.svg)

우선 Subject 인터페이스와 그것을 구현하는 RealSubject와 Proxy 구현합니다. 그리고 Proxy가 RealProxy를 참조하고 있게 됩니다. 그리고 나서 클라이언트가 Subject 인터페이스를 통해서 메소드를 호출하면 Proxy 내 메소드가 호출되고, Proxy 메소드 안에서 RealSubject의 메소드를 대신 호출하게 됩니다.

여기서 프록시가 어떤 역할을 하냐에 따라 가상(Virtual) 프록시와 보호(Protection) 프록시로 나뉘게 됩니다.

#### 가상 프록시

가상 프록시는 실제 객체의 사용시점을 제어할 수 있습니다. 객체의 생성비용이 많이 들어서 미리 생성하기 힘든 객체들의 경우 접근 및 생성시점에 제어합니다. 가령 아래처럼 텍스트 파일을 읽는 인터페이스가 있다고 가정해봅시다.

```java
interface TextFile {
    String fetch();
}
```

메서드가 하나밖에 없는 간단한 인터페이스입니다. 이 때 다음과 같은 요구사항이 주어졌습니다.

> 콘솔 프로그램으로 20개씩 난독화된 전자 서류의 본문을 복호화하여 보여주세요

```java
class SecretTextFile implements TextFile {
    private String plainText;

    public SecretTextFile(String fileName) {
        this.plainText = SecretFileHolder.decodeByFileName(fileName);
    }

    @Override
    public String fetch() {
        return plainText;
    }
}
```

그래서 TextFile을 구현한 SecretTextFile 클래스를 구현하여 난독화 되어있는 텍스트 파일을 복호화해서 평문으로 바꿔주는 클래스를 구현합니다. 이 클래스를 사용하여 콘솔 프로그램을 구현하였습니다. 그런데 실행 시켜보고 첫 결과가 나오기까지 6초라는 시간이 걸렸습니다.

이유를 확인해보니 SecretTextFile 클래스에서 사용중인 SecretFileHolder.decodeByFileName 메소드의 수행속도가 0.3초가 걸렸습니다. 만약 20개의 파일을 로딩하여 복호화한다면 6초가 걸리게 되는 것이었습니다.

그래서 프록시 패턴을 적용하여 필요할 때만 파일 복호화를 하도록 수정하였습니다.

```java
class ProxyTextFile implements TextFile {
    private String fileName;
    private TextFile textFile;

    public ProxyTextFile(String fileName) {
        this.fileName = fileName;
    }

    @Override
    public String fetch() {
        if (textFile == null) {
            textFile = new SecretTextFile(fileName);
        }
        return "[proxy] " + textFile.fetch();
    }
}
```

ProxyTextFile 클래스에서는 객체를 생성할 때에 별다른 동작을 수행하지 않습니다. 하지만 실제로 데이터를 가져와야 하는 시점에 실제 객체인 SecretTextFile 객체를 만들어내고 기능을 위임합니다.

#### 보호 프록시

보호 프록시는 프록시 객체가 사용자의 실제 객체에 대한 접근을 제어합니다.