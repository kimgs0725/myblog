---
title: "JPA2 - JPA 소개"
date: 2021-02-15T23:42:58+09:00
categories:
- spring
tags:
- jpa
- database
---

[이전 포스트]({{< relref "./JPA1.md" >}})에서 말한 문제들을 다시 복습하자면

1. 웹 어플리케이션과 RDB간의 의존성이 생김
2. 웹 어플리케이션과 RDB간의 패러다임 불일치 문제

위 문제를 해결하기 위해 고안한 것이 JPA(Java Persistence API)이다. 간단하게 말하자면 JPA는 데이터를 **자바의 컬렉션**처럼 저장하도록 도와주는 API로 생각하면 편할 것이다.

정확히 말하자면 JPA는 Java 진영의 ORM 기술 표준이다. ORM(Object-relational Mapping)는 객체와 RDB 사이에서 맵핑하는 역할을 하고 있다. 대중적인 언어에선 대부분 표준 ORM이 존재하고 있다.

JPA 내부에 JDBC API를 이용해 쿼리를 보내주고 있다. 이 역할 뿐만 아니라 객체와 RDB 사이에 패러다임 불일치 문제를 해결하는 역할을 수행하고 있다. 이는 우리가 SQL 중심적인 개발이 아닌 객체 중심적인 개발을 하는데 중요한 역할을 하고 있다.

그리고 JPA에서 CRUD를 작성 시, 번거롭게 SQL를 작성안해도 된다. 다음과 EntityManager 클래스의 메소드를 호출해주면 된다. 도메인 객체로 Member가 있다고 가정했을 때,

- 저장: entityManager.persist(member)
- 조회: Member member = entityManger.find(Member.class, memberId)
- 수정: member.setName("JPA1")
- 삭제: entityManager.remove(member)

여기서 수정 기능이 가장 놀라운 기능인 거 같다. 왜나하면 객체를 조회하여 객체 내 멤버변수만 변경해도 JPA가 변경점(Dirty Checking)을 알아채고 UPDATE 쿼리를 날려주기 때문이다.

JPA를 사용함으로써 객체 중심적인 개발이 되었다. 그럼으로써 해결되는 문제를 살펴보자.

1. 웹 어플리케이션과 RDB간의 의존성 문제

    전 포스트에서의 문제를 다시 복습해보자. 다음 도메인 객체가 있다고 가정하자

    ```java
    public class Member {
    	private String id;
    	private String name;
    }
    ```

    그러면 Member 객체를 RDB에 저장하기 위한 CRUD가 존재할 것이다.

    ```sql
    CREATE TABLE MEMBER(
      MEMBER_ID INT NOT NULL,
      NAME VARCHAR(255) NULL,
      PRIMARY KEY(id)
    );

    INSERT INTO MEMBER(MEMBER_ID, NAME) VALUES(1L, "GYEONGSOO");
    SELECT MEMBER_ID, NAME FROM MEMBER;
    UPDATE MEMBER SET NAME = <NAME> WHERE ID = <ID>;
    DELETE FROM MEMBER WHERE ID = <ID>;
    ```

    만약에 Member 도메인 객체에 age를 추가해야한다면 CRUD도 전부 수정을 해야한다. 하지만 JPA에서는 도메인 객체만 수정해주면 CRUD는 JPA가 알아서 쿼리문을 작성하기 때문에 걱정이 없다!! 이렇게 객체 중심적으로 개발을 할 수 있게 된다.

    ```java
    public class Member {
    	private String id;
    	private String name;
    	private int age;
    }
    // 쿼리문을 수정할 필요가 없음!!!
    ```

2. 웹 어플리케이션과 RDB간의 패러다임 불일치 문제

    이전 포스트에서 상속, 연관관계, 엔티티 신뢰를 가지고 애기 했었다. 그럼 JPA가 어떻게 해결해주는지 확인해보자

    우선 상속 문제가 있었다. 이전 포스트에 있던 사진을 보면서 애기해보자.

    ![](/images/JPA1.png)

    Student 객체를 컬렉션에 저장한다고 했을 때, name, age 뿐만 아니라 school_name까지 전부 저장이 된다. 하지만 RDB에선 NAME, AGE 정보를 PERSON 테이블에 저장하고, SCHOOL_NAME은 따로 STUDENT 테이블에 저장해야 한다.

    ```java
    Student student = new Student();
    ...
    // 정보 저장
    list.add(student);  // Person, Student를 따로 저장안해도 됨
    ```

    ```sql
    INSERT INTO PERSON(ID, NAME, AGE) VALUES(1L, "JPA", 30);
    INSERT INTO STUDENT(STUDENT_ID, SCHOOL_NAME) VALUES(2L, "W3SCHOOL");
    ```

    하지만 JPA를 도입하게 되면 웹 어플리케이션처럼 저장하면 쿼리 날리는 것은 JPA가 도맡아서 수행해준다.

    ```java
    Student student = new Student();
    ...
    // 정보 저장
    jpa.persist(student);  // 이후에 INSERT 쿼리는 JPA가 날리게 된다.
    ```

    그리고 조회하는 것도 JPA가 중간에서 테이블에서 조회한 후에 도메인에 값을 넣어서 전달하게 된다.

    ```java
    Student student = jpa.find(Student.class, id);
    // JPA가 중간에서 select join를 보내게 된다.
    ```
    그리고 연관관계 문제도 해결할 수 있다. 다음과 같이 도메인 객체가 있다고 가정하자

    ![](/images/JPA4.png)

    이 다이어그램을 도메인 객체로 표현하면 다음과 같다.

    ```java
    public class Student {
    	private Long id;
    	private Long subject_id;
    	private String username;
    }

    public class Subject {
    	private Long id;
    	private Long professor_id;
    	private String name;
    }

    public class Professor {
    	private Long id;
    	private String name;
    }
    ```

    우선 `Student` 객체를 저장하기 위해서 다음과 같은 순서로 실행한다.

    1. Professor 객체를 professor 테이블에 저장 후 Professor의 id를 Subject 객체 내 professor_id에 저장한다.
    2. Subject 객체를 subject 테이블에 저장 후 Subject의 id를 Student 내 subject_id에 저장한다.
    3. Student 객체를 student 테이블에 저장한다.

    개발자는 Student 객체를 저장하기 위해서 Professor, Subject 객체를 미리 저장해야하는 수고로움이 든다. (물론 어떻게 설계하냐에 따라 다르다. 위에는 설명을 위한 예제)

    Student 객체에서 Professor를 조회하기 위해서 다음과 같은 순서로 실행한다.

    1. Student 객체를 조회한다.
    2. Student 객체에서 subject_id를 가져와서 subject 테이블에 조회한다.
    3. 가져온 Subject 객체에서 professor_id를 가져와서 professor 테이블에 조회한다.
    4. Professor 객체를 얻어온다.

    이처럼 개발자는 Professor를 객체를 조회하기 위해 총 3번의 쿼리를 날려야 한다. 개발자 입장에서는 굉장히 번거로운 일이 아닐 수 없다.

    그럼 JPA에선 어떤 식으로 설계했는지 살펴보자. JPA는 콜렉션에 저장하듯이 설계하면 된다.

    ```java
    public class Student {
    	private Long id;
    	private Subject subject;
    	private String username;
    }

    public class Subject {
    	private Long id;
    	private Professor professor;
    	private String name;
    }

    public class Professor {
    	private Long id;
    	private String name;
    }
    ```

    이런 식으로 도메인 객체를 설계하면 조회도 객체에서 바로 접근이 가능하다는 장점이 있다. 하지만 개발자가 어떻게 조회했냐에 따라서 Student 객체가 subject 멤버변수에 값을 제대로 넣었는지는 알 수 없다.

    ```java
    Student student = jpa.find(Student.class, 1L);
    Subject subject = student.getSubject();
    // Student의 subject에 값이 들어있는 알 수 없음
    ```

    즉, 도메인 간에 신뢰문제가 발생하게 된다. 하지만 JPA를 사용하게 되면 조회 시점에 JPA가 조회를 해서 데이터를 가져온다. 즉, JPA에 의해 Student 내 subject는 무조건 조회할 수 있다는 신뢰관계가 성립된다. 이렇게 JPA가 도메인간의 신뢰문제를 해결해준다.

    이처럼 JPA는 웹 어플리케이션과 RDB 사이에서 맵핑역할을 수행하는 아주 중요한 API이라고 볼 수 있다.
