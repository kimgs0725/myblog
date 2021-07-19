---
title: "JPA4 - 엔티티 매핑"
date: 2021-06-22T20:13:17+09:00
draft: true
categories:
- spring
tags:
- jpa
- database
---

### 객체와 테이블 매핑

JPA에서 엔티티랑 DB 테이블을 정의한 클래스라고 생각하면 됩니다. 엔티티를 통해 간접적으로 DB 테이블을 정의할 수 있게 됩니다. 엔티티의 필드(멤버변수)에 타입과 필드명을 명시하면, DB에 호환되는 테이블을 생성해주는 쿼리문을 생성하게 됩니다. 엔티티 클래스에 필드를 채우게 되면 DB에서 레코드, 혹은 로우(데이터)를 의미하게 됩니다. 엔티티로 사용할 클래스에 `@Entity` 어노테이션을 붙여서 사용할 수 있습니다.

```java
@Entity
class Member {
    ...
}
```

이 때, 기본 생성자(파라미터가 없는)는 필수로 만들어줘야합니다. 클래스 설계에 따라 다르겠지만, 저는 `protected`로 세팅하고 있습니다.(대부분 데이터들은 파라미터가 있는 생성자를 만들어주기 때문입니다.) 그래서 `final`, `enum`, `interface`, `inner` 클래스는 사용할 수 없습니다. 그리고 저장할 필드에 `final` 키워드는 사용할 수 없습니다.

`@Table` 어노테이션은 엔티티와 매핑할 테이블에 대한 정보를 지정합니다. name은 테이블 이름을 지정하는 속성이며 기본값은 엔티티 이름을 사용하고 있습니다. 주로 엔티티 클래스 이름과 DB 내 예약어가 겹칠 때 사용합니다.(ex. Order(JPA) - orders(DB)) 그리고 uniqueConstraints 속성을 통해 유니크 제약 조건을 생성할 수 있습니다.

```java
@Table(uniqueConstraints = {@UniqueConstraint(name = "NAME_AGE_UNIQUE",
                                              columnNames = {"NAME", "AGE"})})
```

### 데이터베이스 스키마 자동 생성

그리고 `@Entity`로 명시한 클래스는 애플리케이션 실행시점에 DDL(Data Definition Language)을 자동으로 생성해줍니다. DDL도 데이터베이스 방언(Dialect)에 따라서 다르게 DDL 형태가 달라질 수도 있습니다. 이렇게 생성된 DDL은 **개발**에서만 사용하도록 합시다. 왜냐하면 JPA에 똑똑하게 DDL을 생성하였지만, 운영환경에서는 상황예 따라 테이블 자체를 튜닝에서 사용할 필요가 있기 때문입니다. JPA에서 스키마 자동 생성을 `applcation.yml`에서 `spring.jpa.hibernate.ddl-auto` 속성을 설정해주면 됩니다.(Default: auto)

|옵션|설명|
|-----|------------------|
|create|기존테이블 삭제 후 다시 생성 (DROP + CREATE)|
|create-drop|create와 같으나 종료시점에 테이블을 DROP|
|update|변경분만 반영(운영DB에는 사용하면 안됨)|
|validate|엔티티와 테이블이 정상 매핑되었는지 확인|
|none|사용하지 않음|

운영 장비에선 절대로 **create**, **create-drop**, **update**로 세팅하면 안됩니다. 그래서 개발 초기 단계에선 **create**, **update**로 세팅하고, 테스트서버에선 **update** 또는 **validate**로 세팅합니다. 그리고 스테이징과 운영서버에선 **validate** 또는 **none**으로 세팅해줍니다. 그럼 운영 서버에는 어떻게 DDL을 업데이트 할까요? 그 방법에 대해서 spring boot에선 [Flyway](https://flywaydb.org/), [Liquibase](https://www.liquibase.org/)라는 DB 스키마 형상관리 툴을 제공하고 있습니다.

### 필드와 칼럼 매핑

테이블 내 필드에 제약조건이라든지 타입을 지정해줄 수 있습니다. 

|어노테이션|설명|
|-------|---|
|@Column|컬럼 매핑|
|@Temporal|날짜 타입 매핑. 최신 하이버네이트에서 `LocalDateTime`을 쓰면 자동으로 날짜 타입으로 매핑시킨다.|
|@Enumerated|enum 타입 매핑|
|@Lob|`BLOB`, `CLOB` 매핑|
|@Transient|특정 필드를 칼럼에 매핑하지 않음(매핑 무시)|

@Column에서 제공하는 속성을 다음과 같습니다.

|속성|설명|기본값|
|---|---|----|
|name|필드와 매핑할 테이블의 칼럼 이름|객체의 필드 이름|
|insertable, updatable|등록, 변경 가능 여부|TRUE|
|nullable(DDL)|null 값의 허용 여부를 설정한다. false로 설정하면 DDL 생성 시에 `not null` 제약조건이 붙는다.||
|unique(DDL)|@Table의 uniqueConstraints와 같지만 한 컬럼에 간단히 유니크 제약조건을 걸 때 사용한다.||
|length(DDL)|문자 길이 제약조건, String 타입에만 사용한다.|255|
|precision, scale(DDL)|BigDecimal 타입에서 사용한다.(BigInteger도 사용할 수 있다.) precious은 소수점을 포함한 전체 자릿수, scale은 소수의 자릿수이다. 아주 큰 숫자나 정밀한 소수를 다루어야 할때만 사용|precious=19, scale=2|

제 경험상, `name`, `nullable`과 `length`을 주로 사용했습니다. 특히, `name` 필드를 세팅하지 않아도 컬럼 이름이 필드 변수명으로 세팅되는데, camel case로 적어도 자동으로 snake case로 변환하여 적용하게 된다.

@Enumerated는 자바의 enum 타입을 DB에 매핑할 때 사용합니다. 이 때, `EnumType`은 기본적으로 `EnumType.ORDINAL`로 세팅되어 있습니다. `EnumType.ORDINAL`은 Enum Class에 정의된 순서대로 숫자를 매핑하여 DB에 저장합니다.

```java
public enum RoleType {
    ADMIN, USER, GUEST // 순서대로 0, 1, 2로 매핑된다.
}
```

하지만 만약에 RoleType에 `DBA`을 맨 앞에 추가한다면 어떻게 될까? 그러면 DBA, ADMIN, USER, GUEST이 각각 0, 1, 2, 3으로 매핑됩니다. 그렇게 되면 그전에 저장된 데이터에 대해서도 RoleType의 의미가 전혀 달라지게 됩니다. ADMIN이었던 계정이 갑자기 DBA가 된다는 뜻입니다. 당연히 이는 서비스 에러로 이어질 수 있습니다. 그러면 어떻게 해야할까요? `EnumType.ORDINAL`을 `EnumType.STRING`으로 변경하면 해결할 수 있습니다. `EnumType.STRING`은 RoleType 내 원소의 이름을 DB에 저장합니다. 그러면 순서에 구애받게 되지않게 되고, DBA 타입이 추가되어도 서비스 에러가 나지 않습니다.

- EnumType.ORDINAL: enum 순서를 DB에 저장 (기본값)
- EnumType.STRING: enum 이름을 DB에 저장

