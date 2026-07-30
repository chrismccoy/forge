# ASCII Layout Skeletons

Match the skeleton for the identified diagram type exactly. Every type follows the same discipline: fixed column spacing, aligned boxes, frames closed on both ends, spaces not tabs.

## sequenceDiagram

```text
Title: <Derived Title>

ClientA          Server          DB
  |                |              |
  |---- login ---->|              |
  |                |--- query --->|
  |                |<-- rows -----|
  |<--- token -----|              |

+== alt: auth ok ============================+
| ...                                        |
+============================================+

Legend:
  ---> forward call    <--- return
  +==+ block frame     |    lifeline
```

## flowchart (TD)

```text
+---------+
|  Start  |
+----+----+
     |
     v
+----+----+     no    +---------+
|  Check? +--------->+  Reject  |
+----+----+          +---------+
     | yes
     v
+----+----+
|  Done   |
+---------+
```

## classDiagram

```text
+------------------+
|     User         |
+------------------+
| + id: int        |
| + login(): bool  |
+------------------+
       | 1
       | owns
       v *
+------------------+
|     Order        |
+------------------+
```

## stateDiagram

```text
( * )
  |
  v
+-----------+   submit   +-----------+
|  Draft    +----------->+  Review   |
+-----------+            +-----+-----+
                               | approve
                               v
                         +-----------+
                         | Published |
                         +-----------+
```

## erDiagram

```text
+----------------+         +----------------+
|    CUSTOMER    |         |     ORDER      |
+----------------+  1    * +----------------+
| PK id          +---------+ PK id          |
| name           |  places | FK customer_id |
| email          |         | total          |
+----------------+         +----------------+
```

## gantt

```text
Title: <Derived Title>           Days ->
                       1   2   3   4   5   6
Design       (T1)  |==========|
Build        (T2)  |       ===============|
Test         (T3)  |                  ========|

Legend:
  ==== task bar    | axis/edge    (Tn) task id
```
