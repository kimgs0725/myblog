---
title: "JPA3 - 영속성 컨텍스트"
date: 2021-06-18T20:05:24+09:00
categories:
- spring
tags:
- spring
- jpa
- database
keywords:
- tech
thumbnailImage: https://innovativetechin.com/Uploads/Images/Icon/1586404155icon.png
---

영속성 컨텍스트(Persistence Context)는 **엔티티를 영구 저정하는 환경**을 의미합니다. 좀 더 쉽게 풀어보자면 DB를 통해 얻어온 데이터들을 저장하는 내부 저장소가 있음을 의미합니다. 내부 저장소가 있음으로서 얻는 이점이 있기 때문입니다.
- 엔티티: 영속성 컨텍스트에 저장되는 도메인(혹은 데이터) 객체

JPA에서는 영속성 컨텍스트에 접근하기 위해 엔티티 매니저(EntityManager)를 사용하고 있습니다. 엔티티 매니저를 통해 엔티티들의 라이프 사이클을 관리할 수 있게 됩니다. 엔티티의 라이프 사이클을 비영속, 영속, 준영속, 삭제 상태가 있습니다.

![](/images/entity_lifecycle.png)

- 비영속(new/transient): 영속성 컨텍스트와 전혀 관계없는 **새로운** 상태. 영속성 컨텍스트가 관리하지 않는 엔티티를 의미합니다.

    ![](/images/detach_entity.png)

    ```java
    Member member = new Member();
    member.setId("member1");
    member.setUsername("회원1");
    ```

- 영속(managed): 영속성 컨텍스트에 **관리**되는 상태. 영속성 컨텍스트에 의해 **엔티티 변경 감지부터 지연 로딩, 동일성을 보장**해줍니다.

    ![](/images/managed_entity.png)
    ```java
    Member member = new Member();
    member.setId("member1");
    member.setUsername("회원1");

    EntityManager em = emf.createEntityManager();
    em.getTransaction().begin()

    // 객체를 영속성 컨텍스트안에 저장한 상태(영속)
    em.persist(member);
    ```

- 준영속(detached): 영속성 컨텍스트에 저장되었다가 **분리**된 상태. 
- 삭제(removed): **삭제**된 상태. 트랜잭션이 끝나면 DB에 삭제 쿼리가 나가게 됩니다.

    ```java
    // 회원 엔티티를 영속성 컨텍스트에서 분리, 준영속 상태
    em.detach(member);

    // 객체를 삭제한 상태(삭제)
    em.remove(member);
    ```

영속성 컨텍스트를 지원함으로써 애플리케이션이 갖는 이점은 다음과 같습니다.

#### 내부적으로 1차 캐시를 갖고 있게 됩니다.

엔티티 매니저를 통해 조회하거나, 생성된 엔티티들 1차 캐시에 저장되게 됩니다. 캐시에 저장된 엔티티들은 고유의 ID를 지니고 있게됩니다. 엔티티를 생성하면 엔티티에 1차 캐시에 저장하게 됩니다. 이후에 해당 엔티티를 조회하게 되면 1차 캐시에 저장된 엔티티를 반환하게 됩니다. 하지만 1차 캐시에 조회하고자 하는 엔티티가 없으면 DB에 select 쿼리를 보내게 됩니다. 그러고 쿼리 결과를 1차 캐시에 저장하고 나서 엔티티를 반환하게 됩니다.

![](/images/entity_cache2.png)

#### 엔티티 간의 동일성(Identity)이 보장됩니다.

1차 캐시에 의해 REPEATABLE READ 수준의 트랜잭션 격리 수준을 데이터베이스가 아닌 애플리케이션에서 지원해줍니다. 영속성 컨텍스트에 의해 관리되는 엔티티는 조회를 해도 같은 엔티티를 반환하게 됩니다.

✧ REPEATABLE READ: [트랜잭션 격리 레벨](https://en.wikipedia.org/wiki/Isolation_(database_systems)#Isolation_levels)의 한 종류로서 read operation을 반복해서 수행하더라도 읽어 들이는 값이 변화되지 않는 정보의 isolation을 보장하는 level입니다.

```java
Member entity1 = em.find(Member.class, "member1");
Member entity2 = em.find(Member.class, "member1");

assertThat(entity1).isEqualTo(entity2);
```

#### 트랜잭션을 지원하는 쓰기 지연(transactional write-behind)

영속성 컨텍스트에 저장되는 엔티티들은 트랜잭션이 끝나기 전까지 DB에 저장되지 않습니다. 대신 쓰기 지연 저장소에 Insert 쿼리문을 저장하고 있디가 트랜잭션이 종료되면 쓰기 지연 저장소에 저장된 쿼리문을 DB으로 보내게 됩니다.

```java
EntityManager em = emf.createEntityManager();
EntityTransaction transaction = em.getTransaction();

transaction.begin();  // 트랜잭션 시장

em.persist(memberA);
em.persist(memberB);
// 이 때까지 INSERT 쿼리를 보내지 않는다.

transaction.commit();   // 트랜잭션 커밋. 이 순간에 INSERT 쿼리를 보내게 된다.
```

![](/images/write_behind1.png)
![](/images/write_behind2.png)

memberA와 memberB를 저장할 때에는 쓰기 지연 저장소에 INSERT 쿼리를 저장해둡니다. 그리고 동일성 보장을 위해 1차 캐시에도 엔티티를 저장합니다. 그리고 나서 `commit` 메소드가 호출되면 쓰기 지연 저장소에 저장해둔 INSERT 쿼리문을 DB로 날리게 됩니다.

![](/images/write_behind3.png)

이렇게 함으로써 저장할 때마다 빈번한 DB I/O를 수행하지 않아도 됩니다. 쓰기 지연 저장소에서 한꺼번에 저장하게 되지만, 너무 많은 INSERT 쿼리가 하나씩 날라가므로 네트워크 낭비가 심해질 수 있습니다. 이는 [JDBC Batching](https://docs.jboss.org/hibernate/orm/5.4/userguide/html_single/Hibernate_User_Guide.html#batch-jdbcbatch) 기능을 이용하여 동일한 엔티티 INSERT 쿼리문을 하나로 묶을 수 있습니다.

```SQL
insert into A values a1
insert into B values b1
insert into A values a2
insert into B values b2


insert into A values (a1, a2)
insert into B values (b1, b2)
```

#### 영속성 컨텍스트 내 엔티티가 변경 사항을 감지합니다. (Dirty Checking)

1차 캐시에 저장된 엔티티는 저장된 순간의 스냅샷을 미리 남겨놓습니다. 그러고나서 엔티티에 변화가 생기게 되면(일부 필드가 바뀐다든지), 엔티티와 스냅샷과 비교합니다.(Dirty Checking) 그리고 나서 변경된 점에 대해 UPDATE 쿼리를 작성하여 쓰기 지연 저장소에 저장합니다. 그리고 쓰기 지연 저장소에 저장된 쿼리문들과 함께 DB에 쿼리를 날리게 됩니다. 이처럼 1차 캐시에 있음으로써 엔티티의 Dirty Checking이 가능해진다는 점이 또 하나의 장점이 됩니다.

```java
EntityManager em = emf.createEntityManager();
EntityTransaction transaction = em.getTransaction();
transaction.begin();

// 영속 엔티티 조회
Member memberA = em.find(Member.class, "memberA");

// 영속 엔티티 데이터 수정
memberA.setUsername("hi");
memberA.setAge(10);

// 수정되기 전 memberA의 스냅샷과 수정된 memberA를 비교하여 UPDATE 쿼리문을 작성하게 됨.
transaction.commit();
```

![](/images/dirty_checking.png)

#### 지연 로딩을 지원합니다. (Lazy Loading)

엔티티는 다른 엔티티와 연관관계를 맺을 수 있습니다.(DB에서 외래키를 갖는다고 하죠!!) 그래서 엔티티를 조회할 때 연관된 다른 엔티티까지 조회하기 위해서 조인 연산을 통해서 얻어오게 됩니다. 하지만 연관관계가 많은 엔티티가 조회된다면 해당 엔티티를 얻기 위해 조인 연산이 많이 일어나게 되고, 이는 성능저하로 이어질 수 있습니다. 이를 위해 JPA에서는 지연 로딩(Lazy Loading)을 지원하고 있습니다. Lazy Loading을 통해 연관된 엔티티가 사용된 시점에 DB에서 SELECT 쿼리를 날려 조회하게 됩니다. 이는 JPA에서 프록시 기능을 지원하기 때문에 가능할 수 있습니다. 프록시에 대해서는 뒤에서 다루도록 하겠습니다.

위에서 쓰기 지연 저장소에 있는 쿼리문을 DB로 날리는 작업을 한다고 했습니다. 그 작업을 플러시(Flush)라고 합니다. 플러시 작업은 EntityManager의 flush 함수를 직접 호출하거나, 트랜잭션 커밋이 발생하거나, JPQL 쿼리가 실행될 때 수행하게 됩니다. 플러시 모드도 변경할 수 있는데 `FlushModeType.AUTO`와 `FlushModeType.COMMIT` 타입이 존재한다. `em.setFlushMode` 함수를 통해 수정할 수 있으며, `FlushModeType.AUTO`는 커밋이나 쿼리를 실행할 때 플러시하는 것을 의미하고, `FlushModeType.COMMIT`은 커밋할 때만 플러시하는 것을 의미합니다. 주로 기본값인 `FlushModeType.AUTO`로 놓고 사용하게 된다. 

```java
em.persist(memberA);
em.persist(memberB);
em.persist(memberC);

// 이 시점에서 멤버 조회 쿼리를 날리면 DB에는 조회가 되지 않는다. (아직 쓰기 지연 저장소에 있는 상태)
// 이는 시멘틱이 맞지 않기 때문에, JPQL을 날리면 그냥 플러시를 하게 된다.
List<Member> members = em.createQuery("select m from Member m", Member.class).getResultList();
```