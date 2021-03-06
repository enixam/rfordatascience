


# lubridate: Dates and times





```r
# lubridate has to be manually loaded
library(lubridate)
library(nycflights13)
library(patchwork)
```

## Creating dates and times

There are generally 3 types of date / time data :

* **date**: Often specified by year, month and day. Tibble prints this as `<date>`  
* **time**：A time within a day, specified by hour, minutes and seconds. Tibble prints this as `<time>`  
* **date-time**: is a date plus a time. Tibbles print this as `<dttm>`. Elsewhere in R these are called `POSIXct`

如果能够满足需要，就应该使用最简单的数据类型。这意味着只要能够使用日期型数据，那么就不应该使用日期时间型数据。 

要想得到当前日期或当前时期时间，可以使用 `today()` 或 `now()` ：  

```r
today()
#> [1] "2020-04-29"
now()
#> [1] "2020-04-29 15:14:49 CST"
```

除此之外，以下 3 种方法也可以创建日期或时间：  

* 通过字符串创建  
* 通过日期时间的各个成分创建  
* 通过现有的日期时间对象创建  


### From strings  
日期时间数据经常用字符串表示。在事先知晓各个组成部分顺序的前提下，通过 `lubridate` 中的一些辅助函数，可以轻松将字符串转换为日期时间格式。因为要想使用函数，需要先确定年、月、日在日期数据中的顺序，然后按照同样的顺讯排列字母 y、m、d，这样就可以组成能够创建日期格式的 `lubridate` 函数名称，例如：  

```r
ymd("2017-03-01")
#> [1] "2017-03-01"
mdy("January 1st,2017")
#> [1] "2017-01-01"
dmy("31-Jan-2017")
#> [1] "2017-01-31"
```

这些函数也可以接受不带引号的数值，这是创建单个时期时间对象的最简单的方法。在筛选日期时间数据时，就可以使用这种方法：

```r
ymd(20190731)
#> [1] "2019-07-31"
```

`ymd()` 和其他类似函数可以创建日期数据。想要创建日期时间型数据，可以在后面加一个下划线，以及h、m、s之中的一个或多个字母（依然要遵循顺序），这样就可以得到解析日期时间数据的函数了：

```r
ymd_hms("2017-01-31 20:11:59")
#> [1] "2017-01-31 20:11:59 UTC"
mdy_hm("01/31/2017 08:01")
#> [1] "2017-01-31 08:01:00 UTC"
```

如果用类似函数尝试解析包含无效内容的字符串，将会返回 NA ：

```r
ymd("2010-10-10", "bananas")
#> [1] "2010-10-10" NA
```



通过添加一个时区参数，可以将一个时期强制转换为日期时间：

```r
## 这是一个日期时间型变量
ymd(20170131, tz = "UTC") 
#> [1] "2017-01-31 UTC"
```

### From individual components   

  


To create a date/time from this sort of input, use` make_date()` for dates, or `make_datetime()` for date-times. Input vectors are silently recycled: 
 

```r
make_datetime(year = 1999, month = 12, day = 22, sec = c(10, 11))
#> [1] "1999-12-22 00:00:10 UTC" "1999-12-22 00:00:11 UTC"
```


This is useful when individual components of data / time is seprated across multiple columns, as in `flights`:   

```r
flights %>% 
  select(year, month, day, hour, minute) %>%
  mutate(departure = make_datetime(year = year, 
                                   month = month, 
                                   day = day, 
                                   hour = hour, 
                                   min = minute))
#> # A tibble: 336,776 x 6
#>    year month   day  hour minute departure          
#>   <int> <int> <int> <dbl>  <dbl> <dttm>             
#> 1  2013     1     1     5     15 2013-01-01 05:15:00
#> 2  2013     1     1     5     29 2013-01-01 05:29:00
#> 3  2013     1     1     5     40 2013-01-01 05:40:00
#> 4  2013     1     1     5     45 2013-01-01 05:45:00
#> 5  2013     1     1     6      0 2013-01-01 06:00:00
#> 6  2013     1     1     5     58 2013-01-01 05:58:00
#> # ... with 336,770 more rows
```

`sec` in `make_datetime()` is unassigned so it defualts to base level 0. This is also how `make_date()` workds 


```r
make_date(year = 2020, day = 20)
#> [1] "2020-01-20"
make_date(month = 12, day = 20)  # year starts in 1970
#> [1] "1970-12-20"
```


`flights` 中 `hour` 和 `time` 均是航班起飞时间的预计值。为了算出实际起飞、到达时间，我们需要使用 `dep_time` 和 `arr_time` 这两个变量，不过，它们同时包括了小时和分钟数：  

```r
flights %>% select(dep_time,
                   arr_time,
                   sched_dep_time,
                   sched_arr_time)
#> # A tibble: 336,776 x 4
#>   dep_time arr_time sched_dep_time sched_arr_time
#>      <int>    <int>          <int>          <int>
#> 1      517      830            515            819
#> 2      533      850            529            830
#> 3      542      923            540            850
#> 4      544     1004            545           1022
#> 5      554      812            600            837
#> 6      554      740            558            728
#> # ... with 336,770 more rows
```

为了创建出表示实际出发和到达时间的日期时间型数据，我们首先编写一个函数以使`make_datetime`函数适应`dep_time`和`arr_time`这种比较奇怪的表示方式，思想是使用模运算将小时成分与分钟成分分离。一旦创建了日期时间变量，我们就在本章剩余部分使用这些变量进行讨论：  

```r
make_datetime_100 <- function(year, month, day, time) {
  hour = time %/% 100
  minute = time %% 100
  make_datetime(year, month, day, hour, minute)
}

(flights_dt <- flights %>%
    filter(!is.na(dep_time), !is.na(arr_time)) %>%
    mutate(
      dep_time = make_datetime_100(year, month, day, dep_time),
      arr_time = make_datetime_100(year, month, day, arr_time),
      sched_dep_time = make_datetime_100(year, month, day, sched_dep_time),
      sched_arr_time = make_datetime_100(year, month, day, sched_arr_time))  %>%
    select(origin,dest,ends_with("delay"), ends_with("time"))
)
#> # A tibble: 328,063 x 9
#>   origin dest  dep_delay arr_delay dep_time            sched_dep_time     
#>   <chr>  <chr>     <dbl>     <dbl> <dttm>              <dttm>             
#> 1 EWR    IAH           2        11 2013-01-01 05:17:00 2013-01-01 05:15:00
#> 2 LGA    IAH           4        20 2013-01-01 05:33:00 2013-01-01 05:29:00
#> 3 JFK    MIA           2        33 2013-01-01 05:42:00 2013-01-01 05:40:00
#> 4 JFK    BQN          -1       -18 2013-01-01 05:44:00 2013-01-01 05:45:00
#> 5 LGA    ATL          -6       -25 2013-01-01 05:54:00 2013-01-01 06:00:00
#> 6 EWR    ORD          -4        12 2013-01-01 05:54:00 2013-01-01 05:58:00
#> # ... with 328,057 more rows, and 3 more variables: arr_time <dttm>,
#> #   sched_arr_time <dttm>, air_time <dbl>
```

我们还可以使用这些数据做出一年间出发时间或某一天内出发时间的可视化分布（精确到分钟）。注意在直方图的分箱宽度中，日期时间数据的单位是秒，而日期数据则是天     


```r
## 一年内起飞时间的分布
flights_dt %>% 
  ggplot() +
  geom_freqpoly(aes(x = dep_time),binwidth = 86400)  ## 86000秒= 1天
```

<img src="lubridate_files/figure-html/unnamed-chunk-14-1.svg" width="672" style="display: block; margin: auto;" />

```r

## 1月1日起飞时间的分布
flights_dt %>% 
  filter(dep_time < ymd(20130102)) %>%
  ggplot(aes(x=dep_time))+
  geom_freqpoly(binwidth = 600)   ## 600秒 = 10分钟
```

<img src="lubridate_files/figure-html/unnamed-chunk-14-2.svg" width="672" style="display: block; margin: auto;" />

### From other times  

You may want to switch between a date-time and a date. That’s the job of `as_datetime()` and `as_date()`:


```r
today() %>% as_datetime()
#> [1] "2020-04-29 UTC"

now() %>% as_date()
#> [1] "2020-04-29"
```

Sometimes you’ll get date/times as numeric offsets from the “Unix Epoch”, 1970-01-01. If the offset is in seconds, use `as_datetime()`; if it’s in days, use `as_date()`.  


```r
# 1 day
as_datetime(60 * 60 * 25)
#> [1] "1970-01-02 01:00:00 UTC"
as_date(1)
#> [1] "1970-01-02"
```

### Exercises  


\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-17"><strong>(\#exr:unnamed-chunk-17) </strong></span>What happens if you parse a string that contains invalid dates?</div>\EndKnitrBlock{exercise}

If returns `NA` and throws a warning:


```r
ymd(c("2010-10-10", "bananas"))
#> Warning: 1 failed to parse.
#> [1] "2010-10-10" NA
```


\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-19"><strong>(\#exr:unnamed-chunk-19) </strong></span>Use the appropriate lubridate function to parse each of the following dates:</div>\EndKnitrBlock{exercise}


```r
d1 <- "January 1,2010"
mdy(d1)
#> [1] "2010-01-01"

d2 <- "2015-Mar-07"
ymd(d2)
#> [1] "2015-03-07"

d3 <- "06-Jun-2017"
dmy(d3)
#> [1] "2017-06-06"

d4 <- c("August 19 (2015)","July 1 (2015)")
mdy(d4)
#> [1] "2015-08-19" "2015-07-01"

d5 <- "12/30/14"  # 2014年12月30日
mdy(d5)
#> [1] "2014-12-30"
```


## Date-time components  

This section will focus on the accessor functions that let you get and set individual components of a date / datetime. 

### Accessing components  


To pull out individual parts of the date with the accessor functions, use： `year()`, `month()`, `mday()`(day of month), `yday()`(day of year), `wday()`(day of week), `hour()`, `minute()`, `second()` ：  

```r
datetime <- ymd_hms("2016-07-08 12:34:56")

year(datetime)
#> [1] 2016
month(datetime)
#> [1] 7
mday(datetime)
#> [1] 8
yday(datetime)
#> [1] 190
wday(datetime)
#> [1] 6
hour(datetime)
#> [1] 12
minute(datetime)
#> [1] 34
second(datetime)
#> [1] 56
```

For `month()` and `wday()` you can set `label = TRUE` to return the abbreviated name of the month or day of the week and convert it to a factor. Set `abbr = FALSE` to return the full name. This is useful when plotting in ggplot2 because you want a certain order  

```r
month(datetime, label = T)
#> [1] Jul
#> 12 Levels: Jan < Feb < Mar < Apr < May < Jun < Jul < Aug < Sep < ... < Dec
wday(datetime, label = T, abbr = F)
#> [1] Friday
#> 7 Levels: Sunday < Monday < Tuesday < Wednesday < Thursday < ... < Saturday
```

通过 `wday()`函数，我们可以知道在工作日出发的航班要多于周末出发的航班：  

```r
flights_dt %>% 
  mutate(weekday = wday(dep_time, label = T)) %>%
  ggplot(aes(weekday)) +
  geom_bar()
```

<img src="lubridate_files/figure-html/unnamed-chunk-23-1.svg" width="672" style="display: block; margin: auto;" />

再看一个使用 `minute()` 函数获取分钟成分的例子。比如我们想知道出发时间的分钟数与平均到达延误时间的关系：  

```r
flights_dt %>% 
  mutate(minute = minute(dep_time)) %>%
  group_by(minute) %>%
  summarize(avg_delay = mean(arr_delay, na.rm = T)) %>%
  ggplot(aes(minute, avg_delay))+
  geom_line()
```

<img src="lubridate_files/figure-html/unnamed-chunk-24-1.svg" width="672" style="display: block; margin: auto;" />

我们可以发现一个有趣的趋势，似乎在 20 ~ 30 分钟和第 50 ~ 60 分钟出发的航班的到达延误时间远远低于其他时间出发的航班。  


### Rounding  
An alternative approach to plotting individual components is to round the date to a nearby unit of time, with  `round_date()`, `floor_date()` and `ceiling_date()`. Each function takes a vector of dates to adjust and then the name of the unit round down (floor), round up (ceiling), or round to. This, for example, allows us to plot the number of flights per week:

```r
flights_dt %>%
  transmute(dep_time,
            week = floor_date(dep_time, "week")) %>%
  ggplot(aes(week))+
  geom_bar()
```

<img src="lubridate_files/figure-html/unnamed-chunk-25-1.svg" width="672" style="display: block; margin: auto;" />

Note that unlike accessor functions, rounding functions still return a complte time unit, not individual components. 

More examples:    

```r
x <- ymd_hms("2009-08-03 12:01:59.23")
round_date(x, ".5s")
#> [1] "2009-08-03 12:01:59 UTC"
round_date(x, "sec")
#> [1] "2009-08-03 12:01:59 UTC"
round_date(x, "second")
#> [1] "2009-08-03 12:01:59 UTC"
round_date(x, "minute")
#> [1] "2009-08-03 12:02:00 UTC"
round_date(x, "5 mins")
#> [1] "2009-08-03 12:00:00 UTC"
round_date(x, "hour")
#> [1] "2009-08-03 12:00:00 UTC"
round_date(x, "2 hours")
#> [1] "2009-08-03 12:00:00 UTC"
round_date(x, "day")
#> [1] "2009-08-04 UTC"
round_date(x, "week")
#> [1] "2009-08-02 UTC"
round_date(x, "month")
#> [1] "2009-08-01 UTC"
round_date(x, "bimonth")   ## 舍入到1月、3月、5月、7月、9月和11月上
#> [1] "2009-09-01 UTC"
round_date(x, "quarter") == round_date(x, "3 months")
#> [1] TRUE
round_date(x, "halfyear")
#> [1] "2009-07-01 UTC"
round_date(x, "year")
#> [1] "2010-01-01 UTC"
```

### Setting components    

You can also use each accessor function to set the components of a date/time:：  

```r
datetime <- ymd_hms("2016-07-08,12:34:56")

year(datetime) <- 2020
month(datetime) <- 11
mday(datetime) <- 05
hour(datetime) <- 01

datetime
#> [1] "2020-11-05 01:34:56 UTC"
```

Alternatively, rather than modifying in place, you can create a new date-time with `update()`. This also allows you to set multiple values at once, the api is similar to `make_datetime()`.

```r
datetime <- ymd_hms("2016-07-08,12:34:56")
update(datetime,year = 2000, month = 11, mday = 05, hour = 01)
#> [1] "2000-11-05 01:34:56 UTC"
```

如果修改`yday`，相当于同时修改 `mday` 和 `month`:

```r
datetime <- ymd_hms("2016-07-08,12:34:56")
update(datetime, yday = 1)
#> [1] "2016-01-01 12:34:56 UTC"
```


If values are too big, they will roll-over: 


```r
ymd("2015-02-01") %>% 
  update(mday = 30)
#> [1] "2015-03-02"

ymd("2015-02-01") %>% 
  update(hour = 400)
#> [1] "2015-02-17 16:00:00 UTC"
```


`update()` 函数还有一种比较巧妙的用法，比如我们想可视化一年中所有航班的的出发时间在一天中的分布：  

```r
flights_dt %>%
  transmute(dep_hour = update(dep_time, yday = 1)) %>%
  ggplot(aes(dep_hour)) +
  geom_freqpoly(binwidth = 60 * 5) + # 1 bin per 5 minutes
  scale_x_datetime(breaks = scales::breaks_width("3 hours"),
               label = scales::label_date_short()) + 
  labs(title = "All flight dep time in a day")
```

<img src="lubridate_files/figure-html/unnamed-chunk-31-1.svg" width="672" style="display: block; margin: auto;" />

如果不用 `update()` ，我们可能需要先用`hour()、minute()、second()`获取三种成分，然后再用`make_datetime()`对这三种成分进行合并。  


### Exercises   

\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-32"><strong>(\#exr:unnamed-chunk-32) </strong></span>以月份作为分组变量，在一年的范围内，航班时间在一天中的分布是如何变化的？ </div>\EndKnitrBlock{exercise}




```r
flights_dt %>%
  mutate(month = month(dep_time, label = TRUE), # this means month is now a factor 
        dep_time = update(dep_time, yday = 1)) %>% # yday can be an arbitary number
  ggplot(aes(dep_time)) +
  geom_freqpoly(binwidth = 60 * 60) + 
  scale_x_time(labels = scales::label_time()) +
  facet_wrap(vars(month), nrow = 4)
```

<img src="lubridate_files/figure-html/unnamed-chunk-33-1.svg" width="768" style="display: block; margin: auto;" />

\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-34"><strong>(\#exr:unnamed-chunk-34) </strong></span>如果想要再将延误的几率降至最低，那么应该在星期几搭乘航班？  </div>\EndKnitrBlock{exercise}



```r
flights_dt %>% 
  mutate(weekday = wday(dep_time, label = T, abbr = T)) %>%
  group_by(weekday) %>%
  summarize(delay_prob = mean(arr_delay > 0, na.rm = T)) %>% 
  ggplot(aes(weekday,delay_prob)) +
  geom_line(aes(group = 1))
```

<img src="lubridate_files/figure-html/unnamed-chunk-35-1.svg" width="672" style="display: block; margin: auto;" />


\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-36"><strong>(\#exr:unnamed-chunk-36) </strong></span>航班预计起飞的小时对应的平均延误时间在一天的范围内是如何变化的？ </div>\EndKnitrBlock{exercise}



```r
flights_dt %>%
  mutate(hour = hour(sched_dep_time)) %>%
  group_by(hour) %>%
  summarize(avg_delay = mean(dep_delay, na.rm = T)) %>%
  ggplot(aes(hour, avg_delay))+
  geom_point()+
  geom_smooth()
```

<img src="lubridate_files/figure-html/unnamed-chunk-37-1.svg" width="672" style="display: block; margin: auto;" />

## Time span {#time-span}

接下来我们将讨论如何对时间进行数学运算，其中包括减法、加法和除法。我们可以把用于进行数学运算的时间称为时间间隔(time span)，它表示一种跨度，而不是某个静态的时间。本节将介绍3种用于表示时间间隔的重要类：   

* **时期（Durations）**：以秒为单位表示一段精确的时间  
* **阶段(Periods)**： 用人类单位定义的时间间隔，如几周或几个月  
* **区间(Intervals)**：由起点和终点定义的一段时间  

### 时期 Durations   

默认情况下，如果我们将两个日期相间，将得到一个 `difftime` 类对象：  


```r
my_age <- today() - ymd(19981112) 
my_age
#> Time difference of 7839 days
```

`difftime` 对象的单位可以是秒、分钟、小时、日或周。这种模棱两可的对象处理起来非常困难，，所以 lubridate提供了总是以秒为单位的另一种时间间隔：**时期**。


```r
as.duration(my_age)
#> [1] "677289600s (~21.46 years)"
```

可以用很多方便的函数来构造时期，它们有统一的格式`d + 时间单位（复数）`：  

```r
dseconds(15)
#> [1] "15s"
dminutes(10)
#> [1] "600s (~10 minutes)"
dhours(c(12,24))
#> [1] "43200s (~12 hours)" "86400s (~1 days)"

ddays(0:5)
#> [1] "0s"                "86400s (~1 days)"  "172800s (~2 days)"
#> [4] "259200s (~3 days)" "345600s (~4 days)" "432000s (~5 days)"
dweeks(3)  ## 没有dmonths()
#> [1] "1814400s (~3 weeks)"
dyears(1)
#> [1] "31557600s (~1 years)"
```

时期 Durations 总是以秒为单位来记录时间间隔。使用标准比率（1 分钟为 60 秒，1 小时为 60 分钟，1 天为 24 小时，1 周为 7 天，一年为 365 天）将分钟、小时、周和年转换为秒，从而建立具有更大值的对象。出于相同的原因，没有`dmonths()`函数, 因为一个月可能有 31 天、30 天、29 天或 28 天，所以 lubridate 不能将它转换为一个确切的秒数。  

可以对时期进行加法和乘法操作：  


```r
2 * ddays(2)
#> [1] "345600s (~4 days)"

dyears(1) + dweeks(12) + ddays(10)
#> [1] "39679200s (~1.26 years)"
```

最重要的，**时期可以和日期时间型数据进行运算** ： 

```r
(tomorrow <- today() + ddays(1))
#> [1] "2020-04-30"

(last_year <- now() - dyears(1))
#> [1] "2019-04-30 09:15:23 CST"
```

然而，因为时期表示的是秒为单位的一个精确数值，有时我们会得到意想不到的结果：  

```r
one_pm <- ymd_hms("2016-03-12 13:00:00", tz = "America/New_York")

one_pm
#> [1] "2016-03-12 13:00:00 EST"
one_pm + ddays(1)
#> [1] "2016-03-13 14:00:00 EDT"
```

为什么3月12日下午 1 点加上一天后变成了下午 2 点？如果仔细观察，就会发现时区发生了变化。因为夏时制，3 月 12 日只有 23 个小时，但我们告诉 R "加上 24 个小时代表的秒数"，所以得到了一个不正确的时间。  



### 阶段 Periods  
为了解决时期对象的问题，`lubridate` 提供了 **阶段** 对象。阶段也是一种 time span，但是它不以秒为单位 ； 相反，它使用“人工”时间，比如日和月。这使得阶段使用起来更加符合习惯  



```r
one_pm
#> [1] "2016-03-12 13:00:00 EST"
one_pm + days(1)  ## 阶段对象
#> [1] "2016-03-13 13:00:00 EDT"
```

`one_pm + days(1)`告诉 R，加上一天，而不是加上多少秒。  

创建阶段对象的函数与时期很类似，只是前面少个“d”，不要把创建阶段的函数与获取时间日期成分的函数搞混了，创建 Periods 的函数都是复数形式：   

```r
seconds(15)
#> [1] "15S"
minutes(10)
#> [1] "10M 0S"
hours(c(12,24))
#> [1] "12H 0M 0S" "24H 0M 0S"

days(7)
#> [1] "7d 0H 0M 0S"
months(1:6)
#> [1] "1m 0d 0H 0M 0S" "2m 0d 0H 0M 0S" "3m 0d 0H 0M 0S" "4m 0d 0H 0M 0S"
#> [5] "5m 0d 0H 0M 0S" "6m 0d 0H 0M 0S"
weeks(3)
#> [1] "21d 0H 0M 0S"
years(1)
#> [1] "1y 0m 0d 0H 0M 0S"
```

可以对阶段进行加法和乘法操作：  

```r
10 * (months(6) + days(10))
#> [1] "60m 100d 0H 0M 0S"
days(50) + hours(25) + minutes(2)
#> [1] "50d 25H 2M 0S"
```

当然，阶段也可以和日期时间型数据进行运算。与 Durations 相比，使用 Periods 得到的计算结果更符合我们的预期：  

```r
## 闰年
ymd("2016-01-01") + dyears(1)
#> [1] "2016-12-31 06:00:00 UTC"
ymd("2016-01-01") + years(1)
#> [1] "2017-01-01"

## 夏时制
one_pm + ddays(1)
#> [1] "2016-03-13 14:00:00 EDT"
one_pm + days(1)
#> [1] "2016-03-13 13:00:00 EDT"
```


There is still one specific problem worth mentioning. That is adding months. Adding months frustrates basic arithmetic because consecutive months have different lengths. With other elements, it is helpful for arithmetic to perform automatic roll over. For example, 12:00:00 + 61 seconds becomes 12:01:01. However, people often prefer that this behavior *NOT* occur with months. For example, we sometimes want January 31 + 1 month = February 28 and not March 3. `%m+%` performs this type of arithmetic. `Date %m+% months(n)` always returns a date in the nth month after Date. If you want minus, `%m-%` does the job.  


```r
jan <- ymd("2010-01-31")

jan + months(1:3) # Feb 31 and April 31 returned as NA, because there is no such date
#> [1] NA           "2010-03-31" NA
jan %m+% months(1:3)
#> [1] "2010-02-28" "2010-03-31" "2010-04-30"
jan %m-% months(1:3)
#> [1] "2009-12-31" "2009-11-30" "2009-10-31"
```


`%m+%` can be also applied to other time span. For example, it is useful when performing arithmetic around a leap year:  


```r
leap <- ymd(20200229)
# test if it is a leap year
leap_year(leap)
#> [1] TRUE

leap + years(c(-1, 1))
#> [1] NA NA
leap %m+% years(c(-1, 1))
#> [1] "2019-02-28" "2021-02-28"
```


下面我们使用 Periods 来解决与航班日期有关的一个怪现象。有些飞机似乎从纽约市起飞前就到达了目的地：  

```r
flights_dt %>%
  filter(arr_time < dep_time) %>%
  select(arr_time, dep_time)
#> # A tibble: 10,633 x 2
#>   arr_time            dep_time           
#>   <dttm>              <dttm>             
#> 1 2013-01-01 00:03:00 2013-01-01 19:29:00
#> 2 2013-01-01 00:29:00 2013-01-01 19:39:00
#> 3 2013-01-01 00:08:00 2013-01-01 20:58:00
#> 4 2013-01-01 01:46:00 2013-01-01 21:02:00
#> 5 2013-01-01 00:25:00 2013-01-01 21:08:00
#> 6 2013-01-01 00:16:00 2013-01-01 21:20:00
#> # ... with 10,627 more rows
```

这些都是过夜航班。我们使用了同一种日期来表示出发时间和到达时间，但这些航班是在第二天到达的。将每个过夜航班的到达时间加上一个`days(1)`，就可以解决这个问题了：  

```r
flights_dt <- flights_dt %>%
              mutate(overnight = arr_time < dep_time,
                      arr_time = arr_time + days(overnight * 1))

## 这样一来，航班数据就符合常理了
flights_dt %>% filter(overnight, arr_time < dep_time)
#> # A tibble: 0 x 10
#> # ... with 10 variables: origin <chr>, dest <chr>, dep_delay <dbl>,
#> #   arr_delay <dbl>, dep_time <dttm>, sched_dep_time <dttm>, arr_time <dttm>,
#> #   sched_arr_time <dttm>, air_time <dbl>, overnight <lgl>
```

### 区间 Intervals   

显然，`dyears(1) / ddays(365)`应该返回1，因为时期总是以秒来表示的，表示 1 年的时间就定义为相当于 365 天的秒数。  
那么`years(1) / days(1)`应该返回什么呢？如果年份 是 2015 年，那么结果就是 365，但如果年份是 2016 年，那么结果就是 366！没有足够的信息让 `lubridate` 返回一个明确的结果。`lubridate` 的做法是给出一个估计值，同时给出一条警告：  

```r
years(1) / days(1)
#> [1] 365
```

如果需要更精确的测量方式，那么就必须使用**区间**。区间是带有明确起点和终点的时期，这使得它非常精确, 可以用 `interval()` 来创建一个区间：  

```r
interval(ymd(20090201), ymd(20090101))
#> [1] 2009-02-01 UTC--2009-01-01 UTC
```

一种更简单的创建区间的方式是使用操作符 `%--%`

```r
next_year <- today() + years(1)
today() %--% next_year 
#> [1] 2020-04-29 UTC--2021-04-29 UTC
```

要想知道一个区间内有多少个阶段，需要使用整数除法。利用区间进行精确计算：

```r
## 闰年
(ymd(20160101) %--% ymd(20170101)) / days(1)
#> [1] 366
## 平年
(ymd(20170101) %--% ymd(20180101)) / days(1)
#> [1] 365
```

### Conclusion


如何在时期、阶段和区间中进行选择呢？只要能够解决问题，我们就应该选择最简单的数据结构。如果只关心物理时间，那么就使用时期 Durations ； 如果还需要考虑人工时间，那么就使用阶段 Periods ； 如果需要找出人工时间范围内有多长的时间间隔，那么就使用区间。  

下图总结了不同数据类型之间可以进行的数学运算： 

<img src="images/1.png" width="316" style="display: block; margin: auto;" />



### Exercises  

\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-57"><strong>(\#exr:unnamed-chunk-57) </strong></span>创建一个日期向量来给出 2015 年每个月的第一天 </div>\EndKnitrBlock{exercise}



```r
ymd(20150101) + months(0:11)
#>  [1] "2015-01-01" "2015-02-01" "2015-03-01" "2015-04-01" "2015-05-01"
#>  [6] "2015-06-01" "2015-07-01" "2015-08-01" "2015-09-01" "2015-10-01"
#> [11] "2015-11-01" "2015-12-01"

## To get the vector of the first day of the month for this year, we first need to figure out what this year is, and get January 1st of it
floor_date(today(), "year") + months(0:11)
#>  [1] "2020-01-01" "2020-02-01" "2020-03-01" "2020-04-01" "2020-05-01"
#>  [6] "2020-06-01" "2020-07-01" "2020-08-01" "2020-09-01" "2020-10-01"
#> [11] "2020-11-01" "2020-12-01"
```


\BeginKnitrBlock{exercise}<div class="exercise"><span class="exercise" id="exr:unnamed-chunk-59"><strong>(\#exr:unnamed-chunk-59) </strong></span>编写一个函数，输入你的生日（日期型），返回你的年龄（以年为单位）：  </div>\EndKnitrBlock{exercise}


```r
age <- function(birth) {
  birth <- ymd(birth)
  (birth %--% today()) %/% years(1)
}

age("19981112")
#> [1] 21
```


## hms


```r
library(hms)
```

The `hms` package provides a simple class for storing durations or time-of-day values and displaying them in the hh:mm:ss format. 


```r
# order: seconds, minutes, hours
hms(56, 34, 12)
#> 12:34:56
hms(56, 34, 12) %>% class
#> [1] "hms"      "difftime"

data.frame(hours = 1:3, hms = hms(hours = 1:3))
#>   hours      hms
#> 1     1 01:00:00
#> 2     2 02:00:00
#> 3     3 03:00:00

as_hms(1)
#> 00:00:01
as_hms("12:34:56")
#> 12:34:56
```

`hms()` is a constructor that accepts second, minute, hour and day components as numeric vectors.


`round_hms()` and `trunc_hms()` are onvenience functions to round or truncate to a multiple of seconds. They are similar to `floor_date()` and `ceiling_date()` in Section \@ref(rounding), but the time unit can only be seconds 


```r
round_hms(as_hms("12:34:56"), sec = 5)
#> 12:34:55
round_hms(as_hms("12:34:56"), sec = 60)
#> 12:35:00
trunc_hms(as_hms("12:34:56"), 60)
#> 12:34:00
```

## dint 

While `lubridate` can handle date & time data in an effective manner, currently it requires the largest unit of a date to be days. This means it does not cover functionality for working with year-quarter, year-month and year-isoweek dates.  

In contrast, `dint` provides a toolkit for these 3 types of date. It stores them in an easily human readable integer format, e.q `20141` for the first quarter of 2014 and so forth. Additionally, it goes hand in hand with `lubridate` in more ways than one. `dint` is implemented in base R and comes with zero external dependencies. Even if you don’t work with such special dates directly, dint can still help you at formatting dates, labelling plot axes, or getting first / last days of calendar periods (quarters, months, isoweeks).   

`dint` provides 4 different S3 classes that inherit from `date_xx` (a superclass for package development purpose).

- `date_yq()` for year-quarter dates  

- `date_ym` for year-month dates 

- `date_yw` for year-isoweek dates  

- `date_y()` for storing years. This is for development purpose, and does not provide notable advantage over storing year as integers.    


```r
library(dint)
```


### Creation  

`date_xx` vectors can be created using explicit constructors  


```r
date_yq(2015, 1)
#> [1] "2015-Q1"
# vectorized 
date_ym(c(2015, 2016), c(1, 2))
#> [1] "2015-M01" "2016-M02"
date_yw(c(2008, 2009), 1)
#> [1] "2008-W01" "2009-W01"
```

It is worth mentioning that `tsibble` also provides similar functions like `yearquarter()`, `yearmonth()` and `yearweek()`. But I think they are generally not flexible in this use case. 

`as_date_xx` coerce other classes (mainly `Date`,  `POSIXct`(time) and `integer`) into `date_xx` objects  


```r
as_date_yq(Sys.time())
#> [1] "2020-Q2"
as_date_yq(20141)
#> [1] "2014-Q1"
as_date_ym(201412) 
#> [1] "2014-M12"
as_date_yw("2018-01-01")  # anything else that can be parsed by as.Date() works
#> [1] "2018-W01"
```

### Arithmetic and Sequences

All `date_xx` support addition, subtraction and sequence generation.  


```r
q <- date_yq(2014, 4)
q + 1
#> [1] "2015-Q1"
q - 1
#> [1] "2014-Q3"
seq(q - 2, q + 2)
#> [1] "2014-Q2" "2014-Q3" "2014-Q4" "2015-Q1" "2015-Q2"
```


### Accessors  

We can access components of `date_xx` (e.g the quarter of a `date_yq`) with accessor functions. You can also use these functions to convert between `date_xx` vectors.


```r
q <- date_yq(2014, 4)
get_year(q)
#> [1] 2014
get_month(q)
#> [1] 10
get_isoweek(q)
#> [1] 40
```

Accessor functions in `dint` are compatible with `Date`, `POSIXct` classes, so are `year()`, `month()` and `day()` in `lubridate` with `date_xx` classes.  


```r
# dint accessor functions on other classes
get_quarter(Sys.Date())
#> [1] 2
get_month(ymd(20200303))
#> [1] 3
get_isoweek(Sys.time())
#> [1] 18

# lubridate accessor functions on date_xx classes 
year(q)
#> [1] 2014
quarter(q) # default to first month in 4th quarter
#> [1] 4
month(q)
#> [1] 10
day(q) # default to 1st day in that month
#> [1] 1
```

`first_of_xx`, `last_of_xx` are 2 helper functions to access the first or last **day** within a specifit span from a `date_xx`, `Date` and `POSIX` object.  


```r
q <- date_yq(2015, 1)

 # the same as as.Date(q), but more explicit
first_of_quarter(q) 
#> [1] "2015-01-01"

last_of_quarter(q) 
#> [1] "2015-03-31"

d <- ymd("20200303")
# first locate the date in a isoweek, then find the first day in that isoweek
first_of_isoweek(d) 
#> [1] "2020-03-02"

last_of_month(d)
#> [1] "2020-03-31"
```


```r
# Alternativeley you can use these:
first_of_yq(2012, 2)
#> [1] "2012-04-01"
last_of_ym(2012, 2)
#> [1] "2012-02-29"
last_of_yw(2012, 2)
#> [1] "2012-01-15"
```

### Formatting  

Formatting date_xx vectors is easy and uses a subset of the placeholders of `base::strptime()`(plus `%q` for quarters)  


```r
q <- date_yq(2014, 4)

format(q, "%Y Q%q")
#> [1] "2014 Q4"
format(q, "%Y.%q")
#> [1] "2014.4"
format(q, "%y.%q")
#> [1] "14.4"

m <- date_ym(2014, 12)
format(m, "%Y-M%m")
#> [1] "2014-M12"

w <- date_yw(2014, 1)
format(w, "%Y-W%V")
#> [1] "2014-W01"
```

There are some shorthands functions for formatting 


```r
format_yq(Sys.Date())
#> [1] "2020-Q2"
format_yq_short(Sys.Date())
#> [1] "2020.2"
format_yq_shorter(Sys.Date())
#> [1] "20.2"

format_ym(Sys.Date())
#> [1] "2020-M04"
format_ym_short(Sys.Date())
#> [1] "2020.04"
format_ym_shorter(Sys.Date())
#> [1] "20.04"
```


### Labelling functions in ggplot2  

There are two ways of making use of `dint` functionality when working with date axis in `ggplot2`  

- use scale `scale_date_**()`, this is implemented by default 
- pass shorthand `format_**` functions to argument `labels` in any scale, this is also applicable to `Date` axes.  



```r
q <- tibble(
  time  = seq(date_yq(2016, 1), date_yq(2016, 4)),
  value = rnorm(4)
)

ggplot(q) + 
  geom_line(aes(time, value)) +
  scale_x_date_ym() + 
  ggtitle("scale_x_yq() by default") -> p1

ggplot(q) + 
  geom_line(aes(time, value)) +
  scale_x_date_ym(labels = format_ym_iso) + 
  ggtitle("labels = format_ym_iso") -> p2

p1 + p2
```

<img src="lubridate_files/figure-html/unnamed-chunk-74-1.svg" width="672" style="display: block; margin: auto;" />

Use `format_**` in `Date` axes   


```r
x <- data.frame(
  time  = seq(as.Date("2016-01-01"), as.Date("2016-08-08"), by = "day"),
  value = rnorm(221)
)

p <- ggplot(
  x,
  aes(
    x = time, 
    y = value)
  ) + geom_point()

p + ggtitle("default")
p + scale_x_date(labels = format_yq_iso) + ggtitle("date_yq_iso")
p + scale_x_date(labels = format_ym_short) + ggtitle("date_ym_short")
p + scale_x_date(labels = format_yw_shorter) + ggtitle("date_yw_shorter")
```

<img src="lubridate_files/figure-html/unnamed-chunk-75-1.svg" width="50%" /><img src="lubridate_files/figure-html/unnamed-chunk-75-2.svg" width="50%" /><img src="lubridate_files/figure-html/unnamed-chunk-75-3.svg" width="50%" /><img src="lubridate_files/figure-html/unnamed-chunk-75-4.svg" width="50%" />

