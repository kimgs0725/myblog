---
title: "프록시 패턴"
date: 2021-06-22T22:15:56+09:00
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

다음과 같은 요구사항이 들어왔다고 가정해봅니다.

> 인사팀에서 인서정보에 대한 데이터 접근을 직책 단위로 세분화할려고 합니다. 원래는 인사팀만 사용한 부분을 다른 직책의 사람들에게도 제공을 해야합니다. 그래서 직책별로 보여줄 수 있는 데이터 접근 레벨을 결정할려고 합니다.

그럼 기존 코드를 한번 살펴보겠습니다.

```java
enum GRADE {
    Staff, Manager, VicePresident
}

interface Employee {
    String getName();
    GRADE getGrade();
    String getInformation(Employee viewer);
}

class NormalEmployee implements Employee {
    private String name;
    private GRADE grade;

    public NormalEmployee(String name, GRADE grade) {
        this.name = name;
        this.grade = grade;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public GRADE getGrade() {
        return grade;
    }

    // 기본적으로 자신의 인사정보는 누구나 열람할 수 있도록 되어있습니다.
    @Override
    public String getInformation(Employee viewer) {
        return "Display " + getGrade().name() + " '" + getName() + "' personnel information.";
    }
}
```

현재 상태에서 Employee 객체를 통해 getInformation 메서드를 통해 정보를 조회할 수 있습니다. 하지만 요구사항에 직책별로 보여줄 수 있는 접근 레벨을 설정해야합니다. 그래서 보호 프록시를 통해 접근 레벨을 설정해줄 수 있습니다.

```java
class ProtectedEmployee implements Employee {
    private Employee employee;

    public ProtectedEmployee(Employee employee) {
        this.employee = employee;
    }

    @Override
    public String getName() {
        return employee.getName();
    }

    @Override
    public GRADE getGrade() {
        return employee.getGrade();
    }

    // 조회할려는 viewer에서 getGrade를 통해 직책을 조회한다.
    // 그리고 나서 현재 Employee를 조회할 레벨이 되는지 검사한다.
    @Override
    public String getInformation(Employee viewer) {
        if (this.employee.getGrade() == viewer.getGrade() &&
            this.employee.getName().equals(viewer.getName())) {
            return this.employee.getInformation();
        }

        switch (viewer.getGrade()) {
            case VicePresident:
                if (this.employee.getGrade() == GRADE.Manager ||
                    this.employee.getGrade() == GRADE.Staff) {
                    return this.employee.getInformation(viewer);
                }
            case Manager:
                if (this.employee.getGrade() == GRADE.Staff) {
                    return this.employee.getInformation(viewer);
                }
            case Staff:
            default:
                throw new NotAuthorizedException();
        }
        return "";
    }
}
```

이 예제에서만 아니라 프록시 패턴은 다양한 프레임워크에서 적용되고 있습니다. 대표적으로 JPA의 지연 로딩(Lazy Loading)을 들 수 있습니다. 외래키로 연결되어 있는 임의의 두 엔티티가 있다고 가정할 때, 엔티티에서 다른 엔티티를 조회할려면 엔티티를 조회한 시점에 조인 연산을 통해 다른 엔티티도 가져와야 합니다. 그런데 너무 많은 조인연산이 일어나는 것을 방지하고자 지연 로딩을 사용하게 됩니다. 이 때, 엔티티 내 연관관계를 가진 엔티티 객체는 프록시 객체를 가지게 됩니다. 그래서 실제 해당 엔티티를 조회한 시점에 DB에 쿼리를 날리게 됩니다. 자세한 내용은 해당 [블로그](https://ict-nroo.tistory.com/131)를 참조해주세요.

#### reference

[JDM's Blog - 프록시 패턴](https://jdm.kr/blog/235)

[ict-nroo - [JPA] 프록시란](https://ict-nroo.tistory.com/131)