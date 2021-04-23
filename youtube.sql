USE liubin;
-- 用户表
CREATE EXTERNAL TABLE youtobe_user
(
    user_name STRING COMMENT '姓名',
    videos    INT COMMENT '上传视频数量',
    friends   INT COMMENT '好友数'
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

LOAD DATA INPATH '/user.txt' INTO TABLE youtobe_user;

SELECT *
FROM liubin.youtobe_user;
-- 视频表
CREATE EXTERNAL TABLE youtube_video
(
    video_id    STRING COMMENT 'id',
    uploader    STRING COMMENT 'a string of the video uploader username',
    age         INT COMMENT 'an integer number of days ',
    category    ARRAY<STRING> COMMENT '分类',
    length      INT COMMENT '视频长度的整数',
    `views`     INT COMMENT '播放量',
    rate        DOUBLE COMMENT '评分',
    ratings     INT COMMENT '流量',
    comments    INT COMMENT '评论数',
    related_ids ARRAY<STRING> COMMENT '相关时评id'
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' COLLECTION ITEMS TERMINATED BY '&' STORED AS TEXTFILE;

LOAD DATA INPATH '/080329.txt.new' INTO TABLE youtube_video;

SELECT
    COUNT(*)
FROM youtube_video;
-- 视频观看数top10
SELECT *
FROM youtube_video
ORDER BY `views` DESC
LIMIT 10;
-- 视频类别热度top10
SELECT *
FROM (
         SELECT
             video_id,
             category_item,
             `views`,
--                 开窗排序
             ROW_NUMBER() OVER (PARTITION BY category_item ORDER BY `views` DESC ) AS rank
         FROM youtube_video
--              侧写分类
             LATERAL VIEW EXPLODE(category) tmp AS category_item
         ) t1
WHERE t1.rank < 10;
-- 视频观看数最高的20个视频的所属类别以及类别包含的top20视频的个数
SELECT
    category_item,
    COUNT(*) AS cate_num
FROM (
         SELECT
             video_id,
             category_item,
             `views`
         FROM youtube_video
             LATERAL VIEW EXPLODE(category) tmp AS category_item
         ORDER BY `views` DESC
         LIMIT 20
         ) t1
GROUP BY category_item;
-- 统计观看数top50 所关联的视频 所属类别排序
-- 1. 观看数前50所关联的视频
-- SELECT related_ids,`views` FROM youtube_video ORDER BY `views` DESC LIMIT 50;t1
--2. 将关联视频id炸开
-- SELECT explode(related_ids)  related_ids_item FROM t1;t2
--3. 关联原数据，取得所属类别
-- SELECT category FROM t2 JOIN youtube_video g ON g.video_id = t2.related_ids_item;t3
--4. 炸开类别数组
-- SELECT explode(category) category_item FROM t3;t4
--5 类别分组求count（*），排序
-- SELECT category_item,count(*) ct FROM t4 GROUP BY category_item ORDER BY ct DESC;
--最终sql

SELECT
    category_item,
    COUNT(*) ct
FROM (
         SELECT
             EXPLODE(category) category_item
         FROM (
                  SELECT
                      category
                  FROM (
                           SELECT
                               EXPLODE(related_ids) related_ids_item
                           FROM (
                                    SELECT
                                        related_ids,
                                        `views`
                                    FROM youtube_video
                                    ORDER BY `views` DESC
                                    LIMIT 50
                                    ) t1
                           )         t2
                  JOIN youtube_video g ON g.video_id = t2.related_ids_item
                  ) t3
         ) t4
GROUP BY category_item
ORDER BY ct DESC;
-- 上传视频最多top10用户，以及所上传视频在观看数top20的视频
EXPLAIN
SELECT *
FROM youtube_video
WHERE video_id IN (
                      -- 观看前20的视频id
                      SELECT
                          t1.video_id
                      FROM (
                               SELECT
                                   video_id
                               FROM youtube_video
                               ORDER BY `views` DESC
                               LIMIT 20
                               )       t1
                      INNER JOIN (
                                     -- 上传前10的用户的视频id
                                     SELECT
                                         video_id
                                     FROM youtube_video
                                     WHERE uploader IN (
                                                           SELECT
                                                               user_name
                                                           FROM youtobe_user
                                                           ORDER BY videos DESC
                                                           LIMIT 10
                                                           )
                                     ) t2 ON t1.video_id = t2.video_id
                      );

