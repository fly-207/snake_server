<!DOCTYPE html>
<html lang="zh-cn">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="renderer" content="webkit">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<title>管理后台-车库源码</title>
<link href="https://cdn.staticfile.org/twitter-bootstrap/3.4.1/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.staticfile.org/layer/2.3/skin/layer.css" rel="stylesheet">
<link href="images/main.css" rel="stylesheet">
<script type="text/javascript" src="https://cdn.staticfile.org/jquery/2.0.0/jquery.min.js"></script>
<script type="text/javascript" src="https://cdn.staticfile.org/twitter-bootstrap/3.4.1/js/bootstrap.min.js"></script>
<script type="text/javascript" src="https://cdn.staticfile.org/layer/2.3/layer.js"></script>
</head>
<body>
  <div class="intro" style="margin-top:30px;">
    <div class="col-md-5 col-centered tac"> <img src="images/logo.png" alt="logo"> </div>
    <div class="container">
      <div class="row">
        <div class="col-md-3 col-sm-8 col-centered">
          <form method="post" autocomplete="off" action="#" novalidate>
            <div class="form-group">
              <input type="text" class="form-control" id="id" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" name="id" placeholder="请输入角色UID" autocomplete="off" required autofocus>
            </div>
            <div class="form-group">
              <select id="type" class="form-control" name="type" ><option value="0">请选择所需要的功能</option><option value="1">发送邮件</option><option value="2">清理背包</option></select>
              </div>
            <div id = 'wupin' style="display:none;">
			<div class="form-group">
			<select id='item' name='item' class="form-control" ><option value='0'>请选择需要发送的道具</option>
            <option value="30600">许仙元神
            </option><option value="30601">璃镜元神
            </option><option value="30602">洛凝霜元神
            </option><option value="30603">渊记元神
            </option><option value="30604">白素贞元神
            </option><option value="30605">小青元神
            </option><option value="30606">法海元神
            </option><option value="30607">道济元神
            </option><option value="30608">龙吉公主元神
            </option><option value="30609">九天玄女元神
            </option><option value="30610">时未寒元神
            </option><option value="30611">昊离归元神
            </option><option value="10001">银币袋
            </option><option value="10002">金箱子
            </option><option value="10004">洗点丹
            </option><option value="10005">轮回丹
            </option><option value="10007">仙灵丹
            </option><option value="10008">炼体丹
            </option><option value="10009">小喇叭
            </option><option value="10010">活力丹
            </option><option value="10012">双倍丹
            </option><option value="10013">双倍丹
            </option><option value="10031">还童丹
            </option><option value="10032">龙血秘藏
            </option><option value="10033">宠物经验丹
            </option><option value="10034">资质人参
            </option><option value="10035">龙魂秘宝
            </option><option value="10036">宠物洗点丹
            </option><option value="10037">宠物轮回丹
            </option><option value="10038">长寿丹
            </option><option value="10039">伏魔袋
            </option><option value="10040">碧玉佩
            </option><option value="10041">糖葫芦
            </option><option value="10042">香包
            </option><option value="10043">陈年酿
            </option><option value="10044">龙睛石
            </option><option value="10045">红玫瑰
            </option><option value="10046">白豆腐
            </option><option value="10047">福寿鱼
            </option><option value="10048">一口闷
            </option><option value="10049">蟹黄金丝粥
            </option><option value="10050">瑶池仙酿
            </option><option value="10051">车前草
            </option><option value="10052">马蹄莲
            </option><option value="10053">酸枣
            </option><option value="10054">玉竹
            </option><option value="10055">天门冬
            </option><option value="10056">北沙参
            </option><option value="10057">回血散
            </option><option value="10058">清心散
            </option><option value="10059">回血丸
            </option><option value="10060">归魂露
            </option><option value="10061">聚灵丸
            </option><option value="10062">定心丹
            </option><option value="10063">大还丹
            </option><option value="10064">九转还魂丹
            </option><option value="10070">战帖
            </option><option value="10071">百灵草
            </option><option value="10072">铆钉
            </option><option value="10073">镜子
            </option><option value="10074">元宝箱
            </option><option value="10075">红玫瑰
            </option><option value="10076">康乃馨
            </option><option value="10077">寻珠令
            </option><option value="10078">大银币袋
            </option><option value="10079">金币宝箱
            </option><option value="10080">老司机
            </option><option value="10081">秋名山车神
            </option><option value="10082">实习车手
            </option><option value="10083">大话粉丝
            </option><option value="10084">大话先锋
            </option><option value="10085">大话元勋
            </option><option value="10086">在线一万年
            </option><option value="10087">半夜练级
            </option><option value="10088">手速极快
            </option><option value="10089">日月同辉
            </option><option value="10090">三界大神
            </option><option value="10091">溜的飞起
            </option><option value="10092">驭灵至尊
            </option><option value="10093">驭灵大家
            </option><option value="10094">驭灵高手
            </option><option value="10095">大话潜龙
            </option><option value="10096">十大俊杰
            </option><option value="10097">第一大帮
            </option><option value="10098">卓越帮派
            </option><option value="10099">十大帮派
            </option><option value="10100">善财童子
            </option><option value="10101">寻宝奇兵
            </option><option value="10102">行走的福缘钥匙
            </option><option value="10103">漂洗专家
            </option><option value="10104">打造专家
            </option><option value="10105">鲜花快递员
            </option><option value="10106">伏魔大师
            </option><option value="10107">怪物杀手
            </option><option value="10108">强化达人
            </option><option value="10147">远古之翼碎片
            </option><option value="10148">喜糖
            </option><option value="10149">远古之翼
            </option><option value="10150">墨家木鸢
            </option><option value="10151">幻灵蝶恋
            </option><option value="10152">龙炎烈焰
            </option><option value="10153">冰晶凤羽
            </option><option value="10154">旭日金羽
            </option><option value="10155">法宝碎片
            </option><option value="10156">法宝精华
            </option><option value="10157">混沌之灵
            </option><option value="10158">魂晶
            </option><option value="10159">九天神翼
            </option><option value="10160">狂欢令
            </option><option value="10161">赤焰纹饰精华
            </option><option value="10162">星噬纹饰精华
            </option><option value="10163">七彩神羽
            </option><option value="10164">星辰沙
            </option><option value="10165">蕴灵珠
            </option><option value="10166">帝宇纹饰精华
            </option><option value="10167">招式秘籍
            </option><option value="10168">商城折扣劵
            </option><option value="10169">神器精华
            </option><option value="10170">天地灵晶
            </option><option value="10171">精灵石
            </option><option value="10172">小雪人元神
            </option><option value="10173">蓝精灵元神
            </option><option value="10174">鞭炮
            </option><option value="10175">银戒指
            </option><option value="10176">金戒指
            </option><option value="10177">钻石戒指
            </option><option value="10178">改名许可证
            </option><option value="10179">帮派改名许可证
            </option><option value="10180">恭喜发财
            </option><option value="10181">清音仙子之灵
            </option><option value="10182">染料
            </option><option value="10183">高级染料
            </option><option value="10184">彩虹果
            </option><option value="10185">五彩缤纷
            </option><option value="10190">速度符
            </option><option value="10191">法防符
            </option><option value="10192">攻击符
            </option><option value="10193">法攻符
            </option><option value="10194">气血符
            </option><option value="10195">法力符
            </option><option value="10196">物防符
            </option><option value="10197">坐骑忘尘丹
            </option><option value="10198">结拜改名许可证
            </option><option value="11038">悬赏令
            </option><option value="11036">纹饰精华
            </option><option value="11037">悬赏礼包
            </option><option value="11039">坐骑经验
            </option><option value="11040">武勋值
            </option><option value="11041">摸金三宝
            </option><option value="11042">宠物护符
            </option><option value="11043">宠物高级护符
            </option><option value="11044">招式经验
            </option><option value="11045">宝石
            </option><option value="11047">高级兽诀
            </option><option value="11048">修炼经验
            </option><option value="11049">古董
            </option><option value="11052">水晶
            </option><option value="11053">藏宝图
            </option><option value="11054">武器装备
            </option><option value="11055">装备元灵
            </option><option value="11056">低级兽诀
            </option><option value="11057">阵法书
            </option><option value="11058">伙伴元神碎片
            </option><option value="11059">伙伴元神
            </option><option value="11060">兽首玛瑙杯
            </option><option value="11061">墨玉砚台
            </option><option value="11062">双龙环佩
            </option><option value="11063">战国玉壁
            </option><option value="11064">兰亭序
            </option><option value="11065">广陵散曲谱
            </option><option value="11066">天王送子图
            </option><option value="11067">焦尾古筝
            </option><option value="11068">青花瓷花瓶
            </option><option value="11069">三足香炉
            </option><option value="11070">白瓷婴儿枕
            </option><option value="11071">连鹤方壶
            </option><option value="11072">寿面纹爵
            </option><option value="11073">长信宫灯
            </option><option value="11074">铜编钟
            </option><option value="11075">建造许可证
            </option><option value="11076">藏宝图
            </option><option value="11077">寻龙令
            </option><option value="11078">摸金符
            </option><option value="11079">阴阳秘术
            </option><option value="11080">风水罗盘
            </option><option value="11082">天极阵
            </option><option value="11083">地覆阵
            </option><option value="11084">风吼阵
            </option><option value="11085">云迷阵
            </option><option value="11086">水灵阵
            </option><option value="11087">火绝阵
            </option><option value="11088">山崩阵
            </option><option value="11089">雷暴阵
            </option><option value="11090">阵法碎片
            </option><option value="11091">神魂碎片
            </option><option value="11092">白水晶
            </option><option value="11093">绿水晶
            </option><option value="11094">蓝水晶
            </option><option value="11095">紫水晶
            </option><option value="11096">橙水晶
            </option><option value="11097">洗炼石
            </option><option value="11098">传音符
            </option><option value="11099">坐骑金丹
            </option><option value="11100">忘魂丹
            </option><option value="11101">冰灵马元神
            </option><option value="11102">怒雷麒麟元神
            </option><option value="11103">九命猫元神
            </option><option value="11104">翻云鲤元神
            </option><option value="11105">青鸾元神
            </option><option value="11106">黄金牛元神
            </option><option value="11107">凌云丹
            </option><option value="11108">流风诀
            </option><option value="11140">情义酒
            </option><option value="11141">情义结
            </option><option value="11142">舞会邀请函
            </option><option value="11143">风云令
            </option><option value="11144">仙友录
            </option><option value="11145">新武器
            </option><option value="11146">许仙信物
            </option><option value="11147">龙吉公主信物
            </option><option value="11148">小青信物
            </option><option value="11149">装备元灵
            </option><option value="11150">洗炼石
            </option><option value="11151">水晶
            </option><option value="11152">藏宝图
            </option><option value="11153">武器装备
            </option><option value="11154">装备图纸
            </option><option value="11155">神秘钥匙
            </option><option value="11156">金钥匙
            </option><option value="11157">情花种子
            </option><option value="11158">情花幼苗
            </option><option value="11159">情花
            </option><option value="11160">白灵晶
            </option><option value="11161">绿灵晶
            </option><option value="11162">蓝灵晶
            </option><option value="11163">紫灵晶
            </option><option value="11164">金圣灵晶
            </option><option value="11165">仙葫元神
            </option><option value="11166">情心
            </option><option value="11167">招式经验书
            </option><option value="11169">红宝石
            </option><option value="11170">黄宝石
            </option><option value="11171">蓝宝石
            </option><option value="11172">紫宝石
            </option><option value="11173">橙宝石
            </option><option value="11174">绿宝石
            </option><option value="11175">珍兽之灵
            </option><option value="11176">神兽之灵
            </option><option value="11177">一级金刚珠
            </option><option value="11178">二级金刚珠
            </option><option value="11179">三级金刚珠
            </option><option value="11180">四级金刚珠
            </option><option value="11181">锻魂锤
            </option><option value="11182">宝石转化符
            </option><option value="11183">九幽令
            </option><option value="11184">技能宝珠
            </option><option value="11185">火龙元灵
            </option><option value="11186">宠物包袱
            </option><option value="11187">瑶池仙露
            </option><option value="11188">宠物经验丹(小)
            </option><option value="11189">造化丹
            </option><option value="11190">福缘钥匙
            </option><option value="11191">云梦狐碎片
            </option><option value="11192">云梦狐元灵
            </option><option value="11193">三眼灵猴元灵
            </option><option value="11194">雪灵兽元灵
            </option><option value="11196">明前龙井
            </option><option value="11197">华丽衣裳
            </option><option value="11198">珍贵药材
            </option><option value="11199">端午祭品
            </option><option value="11200">凌云青霜
            </option><option value="11201">时装礼包
            </option><option value="11202">冰晶凤羽
            </option><option value="12000">30级打造符
            </option><option value="12001">40级打造符
            </option><option value="12002">50级打造符
            </option><option value="12003">60级打造符
            </option><option value="12004">70级打造符
            </option><option value="12005">80级打造符
            </option><option value="12006">90级打造符
            </option><option value="12007">100级打造符
            </option><option value="12008">110级打造符
            </option><option value="12030">30级裁缝符
            </option><option value="12031">40级裁缝符
            </option><option value="12032">50级裁缝符
            </option><option value="12033">60级裁缝符
            </option><option value="12034">70级裁缝符
            </option><option value="12035">80级裁缝符
            </option><option value="12036">90级裁缝符
            </option><option value="12037">100级裁缝符
            </option><option value="12038">110级裁缝符
            </option><option value="12060">30级炼金符
            </option><option value="12061">40级炼金符
            </option><option value="12062">50级炼金符
            </option><option value="12063">60级炼金符
            </option><option value="12064">70级炼金符
            </option><option value="12065">80级炼金符
            </option><option value="12066">90级炼金符
            </option><option value="12067">100级炼金符
            </option><option value="12068">110级炼金符
            </option><option value="12100">50级神魂
            </option><option value="12101">60级神魂
            </option><option value="12102">70级神魂
            </option><option value="12103">80级神魂
            </option><option value="12104">90级神魂
            </option><option value="12105">100级神魂
            </option><option value="12106">110级神魂
            </option><option value="12120">青龙石
            </option><option value="12121">2阶青龙石
            </option><option value="12122">3阶青龙石
            </option><option value="12123">4阶青龙石
            </option><option value="12124">5阶青龙石
            </option><option value="12140">朱雀石
            </option><option value="12141">2阶朱雀石
            </option><option value="12142">3阶朱雀石
            </option><option value="12143">4阶朱雀石
            </option><option value="12144">5阶朱雀石
            </option><option value="13601">赤焰纹饰
            </option><option value="13602">星噬纹饰
            </option><option value="13603">帝宇纹饰
            </option><option value="24001">笋儿元灵
            </option><option value="24002">插翅虎元灵
            </option><option value="24003">如意元灵
            </option><option value="24004">熊猫武师元灵
            </option><option value="24005">桃花妖元灵
            </option><option value="24006">天师道人元灵
            </option><option value="24007">龙人元灵
            </option><option value="24008">雪女元灵
            </option><option value="24009">枪天将元灵
            </option><option value="24010">鬼帝元灵
            </option><option value="29000">一级项圈
            </option><option value="29001">二级项圈
            </option><option value="29002">三级项圈
            </option><option value="29003">四级项圈
            </option><option value="29100">一级铠甲
            </option><option value="29101">二级铠甲
            </option><option value="29102">三级铠甲
            </option><option value="29103">四级铠甲
            </option><option value="29200">一级护符
            </option><option value="29201">二级护符
            </option><option value="29202">三级护符
            </option><option value="29203">四级护符
            </option><option value="30000">潜能
            </option><option value="30001">复仇
            </option><option value="30002">勇猛
            </option><option value="30003">进击
            </option><option value="30004">暗杀
            </option><option value="30005">生命汲取
            </option><option value="30006">溅射
            </option><option value="30007">连斩
            </option><option value="30008">追击
            </option><option value="30009">法术暴击
            </option><option value="30010">法术连斩
            </option><option value="30011">法力波动
            </option><option value="30012">法术增幅
            </option><option value="30013">魔化
            </option><option value="30014">法防忽视
            </option><option value="30015">震荡
            </option><option value="30016">亡魂
            </option><option value="30017">还阳
            </option><option value="30018">定心
            </option><option value="30019">迅捷
            </option><option value="30020">健壮
            </option><option value="30021">物理防御
            </option><option value="30022">法术防御
            </option><option value="30023">物暴抵抗
            </option><option value="30024">土系吸收
            </option><option value="30025">水系吸收
            </option><option value="30026">火系吸收
            </option><option value="30027">风系吸收
            </option><option value="30028">伏魔
            </option><option value="30029">天眼
            </option><option value="30030">戒心
            </option><option value="30031">坚守
            </option><option value="30032">遁法
            </option><option value="30033">拆招
            </option><option value="30034">同仇敌忾
            </option><option value="30035">入定
            </option><option value="30036">灵机一动
            </option><option value="30037">暴击
            </option><option value="30038">地动
            </option><option value="30039">水雷
            </option><option value="30040">心火
            </option><option value="30041">龙卷
            </option><option value="30042">山崩地裂
            </option><option value="30043">冰封万里
            </option><option value="30044">焚天怒火
            </option><option value="30045">风卷残云
            </option><option value="30046">趁势而上
            </option><option value="30047">以牙还牙
            </option><option value="30048">爆破
            </option><option value="30049">金雷震爆
            </option><option value="30050">摧心
            </option><option value="30051">背水一战
            </option><option value="30052">阎罗令
            </option><option value="30053">血脉之力
            </option><option value="30054">星华绽放
            </option><option value="30070">勇敢
            </option><option value="30071">气势
            </option><option value="30072">威慑
            </option><option value="30201">高级复仇
            </option><option value="30202">高级勇猛
            </option><option value="30203">高级进击
            </option><option value="30204">高级暗杀
            </option><option value="30205">高级生命汲取
            </option><option value="30206">高级溅射
            </option><option value="30207">高级连斩
            </option><option value="30208">高级追击
            </option><option value="30209">高级法术暴击
            </option><option value="30210">高级法术连斩
            </option><option value="30211">高级法力波动
            </option><option value="30212">高级法术增幅
            </option><option value="30213">高级魔化
            </option><option value="30214">高级法防忽视
            </option><option value="30215">高级震荡
            </option><option value="30216">高级亡魂
            </option><option value="30217">高级还阳
            </option><option value="30218">高级定心
            </option><option value="30219">高级迅捷
            </option><option value="30220">高级健壮
            </option><option value="30221">高级物理防御
            </option><option value="30222">高级法术防御
            </option><option value="30223">高级物暴抵抗
            </option><option value="30224">高级土系吸收
            </option><option value="30225">高级水系吸收
            </option><option value="30226">高级火系吸收
            </option><option value="30227">高级风系吸收
            </option><option value="30228">高级伏魔
            </option><option value="30229">高级天眼
            </option><option value="30230">高级戒心
            </option><option value="30231">高级坚守
            </option><option value="30232">高级遁法
            </option><option value="30233">高级拆招
            </option><option value="30234">高级同仇敌忾
            </option><option value="30235">高级入定
            </option><option value="30236">高级灵机一动
            </option><option value="30237">高级暴击
            </option><option value="30238">降龙伏虎
            </option><option value="30239">幽冥噬魂
            </option><option value="30240">高级勇敢
            </option><option value="30241">高级气势
            </option><option value="30242">高级威慑</option></select>
            </div>
            <div class="form-group">
              <input type="text" class="form-control" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" id="num" name="num" placeholder="请输入数量 留空为1" autocomplete="off" >
            </div></div>
            <div class="form-center-button">
			  <input class="btn btn-danger" name='pos' id="1" value="提交" type="button" onclick= "test(this)">
			</div><br>
            <div id="divMsg" style="color:#F00" class="validator-tips">©2019 车库源码.All Rights Reserved </div>
          </form>
      </div>
    </div>
  </div>
<script>
$('#type').change(function(){
var gn = $(this).children('option:selected').val();
if(gn == 1 ){
  	document.getElementById('wupin').style.display = "";
}else{
	document.getElementById('wupin').style.display = "none";
}
});

function test(obj){  
    var _status = obj.id;  
    if(_status != '1' || _status == undefined){  
         $('input[name=pos]').attr('id','0'); 		 
         $('input[name=pos]').attr('value','正在提交...');return false;  
    }else{  
         $('input[name=pos]').attr('id','0');  
         post();   
    }    
} 

function post(){
	$.ajaxSetup({contentType: "application/x-www-form-urlencoded; charset=utf-8"});
	$.post("Guozi.php", {
		id:$("#id").val(),
		type:$("#type").val(),
		item:$("#item").val(),
		num:$("#num").val()
	},function(data){ 
            $('input[name=pos]').attr('id','1');  
            $('input[name=pos]').attr('value','提交');
			var gds = ($(window).height()) - 100;
			layer.msg(data,{offset: [gds + 'px',]});
	});
 }
</script>
</body>
</html>