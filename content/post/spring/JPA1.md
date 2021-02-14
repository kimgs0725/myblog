---
title: "JPA1 - JPA 소개"
date: 2021-02-07T15:56:55+09:00
draft: true
categories:
- spring
tags:
- spring
- jpa
- database
---
이번 포스트부터 Spring에서 JPA에 대해서 다뤄볼려고 한다. Spring을 처음 접하면서 Database도 처음 써봤다.(그전에는 OS쪽으로만 개발했었고 Java로 웹 어플리케이션을 개발하는 것은 처음이다.)

그래서 Spring에 대한 지식도 익힐 겸 인프런에서 [김영한](https://www.inflearn.com/users/@yh)님의 강의내용을 정리하는 방식으로 포스트를 써볼려고 한다. (Spring을 처음 접한다면 이분의 강의로 꼭 입문 바란다. 뉴비입장에서 꼼꼼히, 그리고 실무 내용 위주로 강의한다.)

# JPA 배경

현재 웹 어플리케이션을 개발할 때 RDB(Relational DataBase)없이 개발하기 힘든 지경이다.(대부분 돈과 관련된 서비스를 만들 시, RDB는 필수 불가결이다.)

그런데 웹 어플리케이션에서 RDB에 데이터를 저장하기 위해서는 **쿼리문**을 작성해야한다. 웹 어플리케이션(자바 기준)이 이해하는 언어와 RDB이 이해하는 언어(SQL)가 다르기 떄문이다.

그래서 웹 어플리케이션을 작성하는 것과 동시에 쿼리문도 작성해야한다. 즉, 웹 어플리케이션 로직과 RDB를 위한 로직이 분리가 되는데 여기서 문제가 생긴다.

### 웹 어플리케이션과 RDB의 의존성

웹 어플리케이션을 작성할 때, 임의의 테이블에 해당하는 CRUD(Create, Read, Update, Delete)를 작성해야한다. 이는 개발자 입장에서 매우 귀찮은(?) 작업이기도 한다.

만약 MEMBER 테이블이 있다고 가정하자.

```sql
CREATE TABLE MEMBER(
  MEMBER_ID INT NOT NULL,
  NAME VARCHAR(255) NULL
  PRIMARY KEY(id)
);
```

그러면 웹 어플리케이션에서도 RDB의 테이블과 맵핑되는 객체가 필요하게 된다. 이를 **도메인**이라고 부른다고 한다.

```java
public class Member {
	private String id;
	private String name;
}
```

그리고 테이블에 정보는 생성, 조회, 갱신 및 삭제를 위한 쿼리문도 작성해야한다.

```sql
INSERT INTO MEMBER(MEMBER_ID, NAME) VALUES(1L, "GYEONGSOO");
SELECT MEMBER_ID, NAME FROM MEMBER;
UPDATE MEMBER SET NAME = <NAME> WHERE ID = <ID>;
DELETE FROM MEMBER WHERE ID = <ID>;
```

만약 도메인에 필드가 추가되면 어떤 일이 발생하게 될까? 어플리케이션 입장에선 멤버변수 하나 추가해주면 끝나는 일이다.

```java
public class Member {
	private String id;
	private String name;
	private int age;  // age를 추가
}
```

하지만 RDB 입장에서는 추가한 필드를 데이터베이스에 업데이트하는 쿼리문을 하나하나 수정해야한다. 개발자가 일일히 수정하다 보니 쿼리문을 잘못 작성하는 일도 빈번히 일어나게 된다.

```sql
CREATE TABLE MEMBER(
  MEMBER_ID INT NOT NULL,
  NAME VARCHAR(255) NULL,
  AGE INT NULL
  PRIMARY KEY(id)
);

INSERT INTO MEMBER(MEMBER_ID, NAME, AGE) VALUES(1L, "GYEONGSOO", **30**);
SELECT MEMBER_ID, NAME, AGE FROM MEMBER;
UPDATE MEMBER SET NAME = <NAME>, AGE = <AGE> WHERE ID = <ID>;
DELETE FROM MEMBER WHERE ID = <ID>;
```

 이러다 보니 웹 어플리케이션과 SQL 사이에 의존성이 생길 수 밖에 없다.(웹 어플리케이션을 수정하면 SQL 쿼리문도 같이 수정해야한다)

### 패러다임의 불일치

웹 어플리케이션을 작성하다 보면 객체 정보를 저장을 해야하는데, 객체정보를 저장하기 위한 방법은 많지만, 현재로서는 RDB이 최선의 해결책이다. 객체를 RDB에 저장하기 위해서는 SQL로 변환하여 저장한다. 하지만 객체와 관계형 데이터베이스는 엄연한 차이를 두고 있다. 그럼 객체와 RDB간에 무슨 차이가 있을까?

1. 상속

    객체 지향에서 상속관계가 있고 RDB에는 상속 개념은 없지만, Table 슈퍼타입과 서브타입으로 대체 가능하다. 하지만 이게 CRUD를 수행할 때에도 영향을 미친다. 다음 객체와 이와 비슷한 Table 관계가 있다고 가정하자.

    ![](/images/JPA1.png)

    여기서 Student 정보를 저장한다고 했을 때, 객체와 RDB는 저장하는 방식이 다르다. 객체 입장에서는 Student만 저장하면 **다형성**에 의해 `name, age` 뿐만 아니라 `school_name, student_id` 정보가 전부 저장된다. 하지만 RDB는 PERSON 테이블에 `ID, NAME, AGE`를 저장한 뒤에 STUDENT 테이블에 `STUDENT_ID, SCHOOL_NAME` 정보를 저장해야한다.

    그리고 조회를 할 때에도 방식이 다르다. 객체는 Student 정보를 가져오면 **다형성**에 의해 `id, name, age` 뿐만 아니라 `student_id, school_name` 정보가 전부 조회된다. RDB는 PERSON 테이블에서 `ID, NAME, AGE`를 조회하고, 해당 정보와 맵핑되는 STUDENT 테이블에서 `STUDENT_ID, SCHOOL_NAME` 정보를 가져와야 한다.  물론 이를 해결하기 위한 테이블 설계 전략이 많이 나왔지만, 애초에 객체와 RDB간의 패러다임이 안맞기 때문에 생기는 문제이다.

2. 연관 관계

    객체 지향 언어에선 객체 간의 레퍼런스를 이용하여 참조하고 있다. 반면에 RDB에선 테이블 간에 외래키(Foreign Key)로 서로를 참조하게 된다. 다음과 같이 객체와 테이블이 설계되어있다고 가정하자

    ![](/images/JPA2.png)

    객체의 연관관계에서 Student에서 School로 참조는 가능하나, School에서 Student로는 참조할 수 없다. 반면 RDB에선 STUDENT에서 SCHOOL의 FK를 가지고 있기 때문에 SCHOOL 정보를 찾을 수 있고, SCHOOL에서도 STUDENT가 SCHOOL의 FK를 가지고 있기 때문에 쿼리문으로 조회가 가능하게 된다.

    실제로 mybatis에서 도메인을 설계할 때, 주로 FK에 객체 대신 id를 집어넣어서 설계하게 된다.

    ```java
    public class Student {
    	private Long id;
    	private Long school_id;
    	private String username;
    }
    ```

    하지만 객체 패러다임에 맞추어서 id 대신 객체를 집어넣게 되면 애기가 달라진다.

    ```java
    public class Student {
    	private Long id;
    	private School school;  // ID 대신 School 객체
    	private String username;
    }
    ```

    정보를 저장(Insert)를 할 때, SCHOOL 테이블의 FK를 넣어야 한다. `student.getSchool().getId()` 물론 이런 문제는 사소한 문제이긴 하지만, 진짜 문제는 **조회**를 할 때 발생한다. STUDENT 테이블로부터 학생 정보를 받아온 후에, SCHOOL 테이블로부터 다시 학교 정보를 조회해야한다. 만약 한 로우에 FK가 여러개가 있으면, FK 개수만큼 다시 조회하는 로직이 필요하게 된다.

    ```java
    public Student find(Long studentId) {
      // SQL 실행
      Student student = new Student()
      // DB에서 조회한 Student 정보 입력
      School school = new School();
      // DB에서 조회한 School 정보 입력

      student.setSchool(school);
      return student;
    }
    ```

3. 엔티티 신뢰 문제

    그리고 SQL이 보낸 시점에서 비지니스 로직에서 참조할 수 있는 객체가 결정 되버린다. 때문에 **엔티티간의 신뢰문제가 발생하게 된다**. 이게 무슨 말이냐면, 다음 예제를 보자

    ![](/images/JPA3.png)

    ```java
    public class Student {
    	private Long id;
    	private School school;
    	private Subject subject;
    	private String username;
    }

    public Student find(Long studentId) {
    	// SQL 실행
    	Student student = new Student();
    	...
    	return student;
    }
    ```

    만약 도메인을 다음과 같이 설계했다고 가정하고, 조회하는 로직을 구현했다고 가정하자. 이 때, 조회를 하는 시점에 Student 객체가 Subject 객체를 가지고 있다고 신뢰할 수 있을까? 그건 조회하는 비지니스 로직을 까보지 않는 이상 확신할 수 없다. 그리고 Subject 객체에서 Class 객체를 참조할 수 있을까? 비지니스 로직을 확인하지 않는 이상 엔티티 간에 신뢰성은 떨어지게 된다.

    ```java
    Student student = find(studentId);
    Subject subject = student.getSubject();  // NULL??
    Class class1 = subject.getClass();       // NULL??
    ```