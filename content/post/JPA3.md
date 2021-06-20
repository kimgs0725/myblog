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

엔티티 매니저를 통해 조회하거나, 생성된 엔티티들 1차 캐시에 저장되게 됩니다. 캐시에 저장된 엔티티들은 고유의 ID를 지니고 있게됩니다.
생성: 엔티티를 생성하면 1차 캐시에 저장하게 됩니다. 이후에 트랜잭션이 종료되면 캐시에 저장한 새 엔티티들을 저장하는 Insert 쿼리를 보내게 됩니다.

![](/images/entity_cache1.png)

조회: 조회를 하면 우선 1차 캐시에 있는지 검사합니다. 1차 캐시에 조회하고자 하는 엔티티가 있으면 바로 가져옵니다. 하지만 1차 캐시에 조회하고자 하는 엔티티가 없으면 DB에 select 쿼리를 보내게 됩니다. 그러고 쿼리 결과를 1차 캐시에 저장하고 나서 엔티티를 반환하게 됩니다.

![](/images/entity_cache2.png)

#### 엔티티 간의 동일성(Identity)이 보장됩니다.

1차 캐시에 의해 REPEATABLE READ 수준의 트랜잭션 격리 수준을 데이터베이스가 아닌 애플리케이션에서 지원해줍니다. 영속성 컨텍스트에 의해 관리되는 엔티티는 조회를 해도 같은 엔티티를 반환하게 됩니다.

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

{{< image classes="floatleft" src="/images/write_behind1.png" >}}
{{< image classes="floatright" src="/images/write_behind2.png" >}}


#### 영속성 컨텍스트 내 엔티티가 변경 사항을 감지합니다. (Dirty Checking)


- 지연 로딩을 지원합니다. (Lazy Loading)