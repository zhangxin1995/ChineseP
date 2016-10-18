function string.split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function getLength(str)
	local fontSize = 20
    local lenInByte = #str
    local count = 0
    local i = 1
	local line={}
    while true do
        local curByte = string.byte(str, i)
        if i > lenInByte then
            break
        end
        local byteCount = 1
        if curByte > 0 and curByte < 128 then
            byteCount = 1
        elseif curByte>=128 and curByte<224 then
            byteCount = 2
        elseif curByte>=224 and curByte<240 then
            byteCount = 3
        elseif curByte>=240 and curByte<=247 then
            byteCount = 4
        else
            break
        end
        i = i + byteCount
        count = count + 1
    end
    return count
end


function GetString(str)
    local fontSize = 20
    local lenInByte = #str
    local count = 0
    local i = 1
	local line={}
    while true do
        local curByte = string.byte(str, i)
        if i > lenInByte then
            break
        end
        local byteCount = 1
        if curByte > 0 and curByte < 128 then
            byteCount = 1
        elseif curByte>=128 and curByte<224 then
            byteCount = 2
        elseif curByte>=224 and curByte<240 then
            byteCount = 3
        elseif curByte>=240 and curByte<=247 then
            byteCount = 4
        else
            break
        end
        local char = string.sub(str, i, i+byteCount-1)
        i = i + byteCount
        count = count + 1
		line[count]=char
    end
    return line,count-1
end

Word={}
function Word.new(str,f)
	return {text=str,freq=f}
end

Chunk={}
function Chunk:new(o)
	self.words={}
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
function Chunk:getLength(i)
	return getLength(self.words[i].text)
end

function Chunk:display()
	local i
	for i=1,#self.words do
		print("print chunk "..self.words[i].text)
	end
end

function Chunk:add(w)
	table.insert(self.words,w)
end
function Chunk:totalWordLength()
local sum=0
	for i=1,#self.words do
		sum=sum+getLength(self.words[i].text)
	end
	return sum
end
function Chunk:averageWordLength()
	return self:totalWordLength(self.words)/#self.words
end

function Chunk:standardDeviation()
	local average=self:averageWordLength()
	local sum=0;
	for i=1,#self.words do
		local tmp = (self:getLength(i) - average)
		sum=sum+tmp*tmp
	end
	return sum
end

function Chunk:WordFreqence()
	local sum=0
	for i=1,#self.words do
		sum=sum+self.words[i].freq
	end
	return sum
end


local words=Chunk:new()

dict={maxWordLength = 0,dictword={}}
function dict:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
function dict:loadDict(path)
	local dictFile=io.open(path,"r")
	if dictFile ~= nil then
		local line=dictFile:read()
		while(line~=nil) do
			line=string.split(line,",")
			local word=line[2]
			local freq=line[3]
			local strnum=getLength(word)
			self.dictword[word]={strnum,freq}
			if self.maxWordLength < strnum then
				self.maxWordLength =strnum
			end
			line=dictFile:read()
		end
		io.close(dictFile)
	else print("Load dict fail! Path:"..path)
	end
end
function dict:getWord(word)
	if self.dictword[word]~=nil then
		return Word.new(word,self.dictword[word][2])
	else
		return nil
	end
end
ComplexCompare={}
function ComplexCompare:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end
function ComplexCompare:takeHightest(chunks,comparator)
	local i=1
	local j
	local newchunks={}
	for j=2,#chunks do
		local rlt=comparator(chunks[j],chunks[1])
		if rlt>0 then
			i=1
		end
		if rlt>=0 then
		chunks[i],chunks[j]=chunks[j],chunks[i]
		i=i+1
		end
	end
	for j=1,i do
		table.insert(newchunks,chunks[i])
	end
	return newchunks
end
function ComplexCompare:mmFilter(chunks)
	local function comparator(a,b)
		return a:totalWordLength()-b:totalWordLength()
	end
	return self:takeHightest(chunks,comparator)
end

function ComplexCompare:lawFilter(chunks)
	local function comparator(a,b)
		return a:averageWordLength()-b:averageWordLength()
	end
	return self:takeHightest(chunks,comparator)
end
function ComplexCompare:svmFilter(chunks)
	local function comparator(a,b)
		return a:standardDeviation()-b:standardDeviation()
	end
	return self:takeHightest(chunks,comparator)
end

function ComplexCompare:logFreqFilter(chunks)
	local function comparator(a,b)
		return a:WordFreqence()-b:WordFreqence()
	end
	return self:takeHightest(chunks,comparator)
end


Analysis={}
function Analysis:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
function Analysis:setText(text)
	local i
	self.text=text
	self.pos = 1
    self.textLength = string.len(self.text)
    self.cacheIndex = 0
    self.complexCompare = ComplexCompare:new()
end
function Analysis:iter()
	local token=self:getNextToken()
	return token
end
function Analysis:getNextChar()
    local count = 0
    local i = 1
	local line={}
	local curByte = string.byte(self.text, self.pos)
    local byteCount = 1
    if curByte > 0 and curByte < 128 then
        byteCount = 1
    elseif curByte>=128 and curByte<224 then
        byteCount = 2
    elseif curByte>=224 and curByte<240 then
        byteCount = 3
    elseif curByte>=240 and curByte<=247 then
        byteCount = 4
	end
    local ch = string.sub(self.text, self.pos,self.pos+byteCount-1)
    return ch,byteCount
end
function Analysis:isChineseChar(str)
	local curByte = string.byte(str,1)

	if curByte >=228 and curByte <= 233 then
		local c1 = string.byte(str,2)
		local c2 = string.byte(str,3)
		if c1 and c2 then
			local a1,a2,a3,a4 = 128,191,128,191
			if c == 228 then a1 = 184
			elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
			end
			if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
				return true
			end
		end

    end
	return false
end
function Analysis:isASCIIChar(ch)
	local curByte = string.byte(ch,1)
	if (curByte >=65 and curByte <=90 ) or (curByte >=97 and curByte <=122 ) or (curByte >=48 and curByte <=57 ) then
		return true
    end
	return false
end


function Analysis:getNextToken()

        while self.pos < self.textLength do
            if self:isChineseChar(self:getNextChar()) then
                token = self:getChineseWords()
            else
                token = self:getASCIIWords().."/"
			end
            if string.len(token) > 0 then
                return token
			end
		end
        return nil
end


function Analysis:getASCIIWords()
	local stop,start,ch,snum
	while self.pos < self.textLength do
		ch ,snum= self:getNextChar()
		if self:isASCIIChar(ch) or self:isChineseChar(ch) then
                break
		end
		self.pos =self.pos +1
	end
	local start = self.pos

	while self.pos < self.textLength do
		ch = self:getNextChar()
		if not self:isASCIIChar(ch) then
			break
		end
		self.pos =self.pos+ 1
	end
	local stop= self.pos
	while self.pos < self.textLength do
		ch,snum= self:getNextChar()
		if self:isASCIIChar(ch) or self:isChineseChar(ch)then
			break
		end
		self.pos = self.pos+snum
	end
	return string.sub(self.text,start,stop)
end
function Analysis:getChineseWords()
	local i

	local chunks=self:createChunks()
	if #chunks>1 then
		chunks=self.complexCompare:mmFilter(chunks)
	end
	if #chunks>1 then
		chunks=self.complexCompare:lawFilter(chunks)
	end
	if #chunks>1 then
		chunks=self.complexCompare:svmFilter(chunks)
	end
	if #chunks>1 then
		chunks=self.complexCompare:logFreqFilter(chunks)
	end
	if #chunks==0  then
		return ""
	end
	local words=chunks[1].words
	local token=""
	local length=0
	local i
	for i=1,#words do
		if words[i].freq~=-1 then
			token=token..words[i].text.."/"
			length=length+string.len(words[i].text)
		end
	end
--~ 	print(#words)
	self.pos=self.pos+length
	return token
end
function display(m,words)
	local i
	for i=1,#words do
		print(m.." display :"..words[i].text)
	end
end

function Analysis:createChunks()
	local chunks={}
	local originPos=self.pos
	local i,j,k,words1,words2,words3
	local chunk=Chunk:new()
	words1=self:getMatchChineseWords()
--~ 	display("i",words1)
	for i=1,#words1 do
--~ 		print("i"..i)
		self.pos = self.pos+string.len(words1[i].text)
--~ 		print("pos "..self.pos .." "..self.textLength)
		if self.pos<self.textLength then
			words2 = self:getMatchChineseWords()
--~ 			display("j",words2)
			for j=1,#words2 do
				self.pos = self.pos+string.len(words2[j].text)
				if self.pos<self.textLength then
					words3 = self:getMatchChineseWords()
--~ 					display("k",words3)
					for k=1,#words3 do
						local m=chunk
						chunk=Chunk:new()
						chunk:add(words1[i])
						--if(words2[j].freq~=-1 )  then
							chunk:add(words2[j])
						--end
						if words3[k].freq~=-1 then
							chunk:add(words3[k])
						else
							--print("True")
						end
--~ 					chunk:display()
					table.insert(chunks,chunk)
					end
				elseif self.pos==self.textLength+1 then
					chunk=Chunk:new()
					chunk:add(words1[i])
					chunk:add(words2[j])

					table.insert(chunks,chunk)
				end
				self.pos=self.pos-string.len(words2[j].text)
			end
		elseif self.pos==self.textLength+1 then
			chunk=Chunk:new()
			chunk:add(words1[i])
			table.insert(chunks,chunk)
		end
		self.pos=self.pos-string.len(words1[i].text)
	end
	self.pos=originPos
	return chunks
end


--运用正向最大匹配算法结合字典来切割中文文本
function Analysis:getMatchChineseWords()
	local originPos=self.pos
	local words={}
	local index=0
	while self.pos<self.textLength do
		if index >=dictword.maxWordLength then
		break
		end
		local ch,snum=self:getNextChar()
		if not self:isChineseChar(ch) then
			break
		end
		self.pos=self.pos+snum
		index=index+1
		local text=string.sub(self.text,originPos,self.pos-1)

		local word=dictword:getWord(text)

		if word~=nil then
			table.insert(words,word)
		end
	end
	self.pos=originPos
	if table.getn(words)==0 then
		local word=Word.new()
		word.freq=-1
		word.text="X"
		table.insert(words,word)
	end


	return words
end

function Analysis:display()
	str=""
	while(true) do
		token=self:getNextToken()
		if token==nil then
			break
		end
		str=str..token
	end
	print(str)
end
function test()
	local tana=Analysis:new()
--~ 	tana:setText([[作者：匿名用户链接：https://www.zhihu.com/question/51643337/answer/126845663来源：知乎著作权归作者所有，转载请联系作者获得授权。很多人觉得明凯是怂，我觉得他不是怂，是菜。这么多年联赛与俱乐部的宣传，解说与粉丝的吹嘘，把他捧的太高了，lpl赛区实力的下滑，这让他和EDG给人一种确实不错的错觉，所以每次出问题，总让人觉得他就是怕背锅，怂。他只会刷野，主要还是打野思路呆板，容易被对手研究，以及节奏不如别人的缘故。别人开始带节奏了，他正在在刷，别人带崩三路多路联动了他也只能刷了。一句话概论就是菜，不如别人。偏偏他自己还是那种自我感觉良好的人，S3全明星以来，各种骚话被人当作笑料。其实纵观明凯的职业生涯，WE时期是个十足的混子，当初队里估计只有他和卷毛的人气最低吧，卷毛毕竟是辅助，国内对于辅助的认识很滞后，一直到韩国两代M神之后才意识到辅助的重要性，加上下路面瘫的光芒太耀眼，所以当时被忽视很正常，明凯绝对的是因为毫无亮点的原因。S3 WE的爆炸，最耀眼的几位明星都被黑惨了，反倒是最低调的两个没什么可黑的，离队事件一时间成了粉丝和黑粉对于WE哀其不幸怒其不争的痛斥，明凯一时间获足了威望。S4 EDG的异军突起。其实明凯S4确实没有后来那么多黑点，算得上个人巅峰，舆论也是从S4开始转变开始吹捧明凯与他的梦想。正如我所说盛名之下 其实难副，明凯一直算不上顶尖打野，S4 Dandy的EQ闪教做人也是让人印象深刻。明凯的声望在MSI夺冠后到达巅峰后一直到今天S6，中间虽然略有起伏，可总体是不变的，风向也没有变，如今墙倒众人推，多少解说退役选手暗讽，可帮他说话的却还是WE那帮老队友，那个被他跳舞的AD，那个被他死亡凝视的抗压上单，那个四大皆空的混吃等死的中单......想想也是讽刺。当初最混的是他，可自己的队友从来没亏待他，把他当兄弟，S3末期的WE最后几场的消极比赛，鱼死网破，和队伍有人混吃等死，既然大家都没本事就各走各路，后来WE换了中单后据说还说出早知道找来这么好的中单当初就不走了这样的话，说句诛心的，这种人的人品，啧啧。当年WE的解散最大的锅给了最早退役的掌门，明凯却靠着它来发家。我在等猪仔教我什么是梦想呢……看了知乎关于明凯的很多提问，发现不管是回答还是评论，一大片猪仔，所以对于我这种一直以来对比赛的热情高于游戏的低端玩家嘴强王者来说，我多多少少的麻木了。哀其不幸，怒其不争。与其说是我对于lpl某些选手或者赛区的态度，不如说是对于国内广大粉丝的态度罢了。回顾lpl几代天团的兴衰，最早的WE，IPL冠军，国内第一个世界冠军，当年的S2也是因为“被拔网线”，留给人太多遗憾；OMG，S3时期异军突起，S3小组赛与如日中天的SKT互有胜负，S4 50血翻盘，零封白盾，在韩国人已经统治这个游戏的时代，给了国内玩家太多的感动，仔细想想，这也是我们这么些年少有的赢过韩国人的BO5，赢得还是如此的漂亮。这两个战队，在达到各自巅峰的时候，迅速吸引了大量粉丝，随后极盛而衰，天团陨落，他们的粉丝，也如同丧家之犬一样被各大贴吧掉打嘲讽。S2时期，韩国人还没有崛起，欧美的统治力还是下降，那个时期，多多少少有些群雄逐鹿的感觉。国内WE与IG双雄争霸，还记得那年龙争虎斗杯韩国人耍诈，依旧被我们掉打，现在想想，不禁唏嘘。那一年，掌门还不是畜生，那一年S2，我们有两个八强队伍。S3时期，OMG黑马异军突起，WE开始陨落，那一年诞生了无数的梗，吾王的300刀，司马布的姐姐，掌门的落地生财，原地闪现，重置普攻，完成被lpl所有中单单杀的成就，很少有人提及他最后把所有中单都单杀回来的事；杀马特皇族被60e诅咒坠机，小狗被小猪Q死在兵堆塔下，为什么不办武器，tabe的上帝之手；灵药的瞎子第一次在世界赛上大放异彩，木马的鳄鱼无敌绕后，OMG第一次开始有了欠条……那一年，tabe还是电竞鲁迅，那一年，我们有一个八强，一个亚军。S4时期，春季赛的菜鸡互啄让人感到可气又可笑，夏季赛韩援初次入华。经历了“叛徒”离队后重组的新WE在微笑与草莓的坚持下依旧未能进入S赛；小狗转去中单后皇族差点降级，当年全明星被明凯证明的打野加入皇族，最后虽然还是未能夺冠，可是依旧捍卫了lpl赛区的荣誉，依旧压着mata与小婊砸的下路一头，那一年，在我看来是小狗的个人巅峰；明凯与卷毛的EDG成了黑马，以一号种子身份杀入S赛有一次帮助明凯卫冕八强，虽然那逼永远忘不了那碗牛肉面，可是我却无法否定他与U格斯撑起EDG内战战绩的所做的贡献和lpl的中路一度被U格斯支配的恐惧；OMG经历了全明星的落败，老状态的伤病，最后杀入S赛，首场败于LMQ，被SSB血虐，捞状态亚索被发条单杀，出线渺茫，破釜沉舟，50血翻盘Fnatic，八强赛零封白盾，一场比赛成就了笑笑的解说。那一年，小狗还不洗澡，老状态还没有登基，木马还不会旋转，灵药也不是毒药，小伞还是蓝领AD的巅峰，明凯考虑要不要换爹；那一年，我们有一个八强，一个四强，一个亚军；那一年，欧美还是捞逼。S5时期，韩援大量涌入lpl。三星十子全部来华。EDG的MSI冠军让这个赛区空前膨胀，我们一度自信，韩国人的统治力已经不在，我们已经是第一赛区。S5的表现令人影响深刻：EDG与外卡强行55开最后翻盘，被Fnatic打了4：0，MSI最大功臣被EDG雪藏，关键时刻拿来背黑锅，明凯表示，不光F4，连三狼也是我的，三少的日记一次次挑战我的下限让我开始怀疑这个战队的老板到底是不是傻逼；LGD的道理我都懂，为什么不办铁男，高德伟的反向Q并不能射到S6，淘宝权成了最大的黑锅侠，虽然他在对面4ap的阵容下布甲鞋兰盾出装确实让人看不懂；IG在完成校长不吃翔的任务后功成身退。那一年，tabe化身电竞汪精卫，TT替EDG背了口大锅，至今下落不明，kakao日后下放lspl彻底挖煤，淘宝权与LGD恩断义绝……那一年，我们只有一个八强。S6赛事至今，我就不罗嗦了。商人是逐利的，抛开这点来看lpl就是扯淡，所谓电竞（lpl），不过是风口上的猪罢了。在这块环境还没有如此浮躁的时候，没有那么高的工资，没有那么多主播，没有那么多破事的时候，我们还是能够出成绩的，哪怕不能做世界第一，我们总有值得我们骄傲的成绩，值得期待的未来。后来，随着英雄联盟的火热，职业化的推进，敏感的资本家嗅到了资本的气息，开始大力介入。lpl越办越高逼格，规模也在扩大，选手工资变高，韩援越来越多……我们的成绩越来越差，其实八强不是关键，关键在于一次次的国际比赛让我们失望乃至绝望。我们以前嘲讽欧美捞逼，嘲讽湾湾，我们眼里只有韩国，这两年的S赛却一次次打我们的脸，我不禁怀疑韩援对于lpl的意义到底在哪？国内第一的队伍能够与外卡从55开到被外卡血虐，以前看不起的欧美能在BO5里打我们一个4：0，我们眼里依旧以韩国为目标，可我们的表现还对得起我们的心高气傲吗？这几年S赛的惨败不是年年八强，而是我们的战绩越来越捞。韩国人崛起后他们的统治力是绝对的，即使当时以第二赛区自居的我们也是被他们血虐，韩援的涌入，不过是一种投机取巧，揠苗助长，实际上不过是自欺欺人，饮鸩止渴。大量韩援的涌入，提高了lpl内部竞争不假，却使得我们不再愿意培养新人，过分依赖韩援。刻意营造的国内假象，一次次被国外队伍打脸。联赛以S冠军这一目前看来遥不可及的梦想为诱饵，吸引着我们这些粉丝的注意力，背后的他们赚的盆满钵满。为什么明凯被吹成这样？因为韩援泛滥的今天，lpl需要有本土代表选手扛起大旗，所以在矮子里面选将军，他的梦想，他的坚持，被联赛，俱乐部，解说，退役主播以及粉丝，一吹再吹，明凯生日比赛现场庆生，QG队员干坐在台上半个多小时让人莫名心疼，可是我看到的是他在S赛的表现化作一个又一个的梗，然后俱乐部发表声明，表示道歉，接着拿着梦想，再捞一年。韩援泛滥的今天，全华班这个在lpl本因该天经地义的事变成了个别俱乐部鼓吹情怀，恶意营销的资本和大量粉丝因为出不了成绩而嘲笑的对象，这是一种何等的扭曲？有人会说俱乐部又不是国家队，有外援怎么了？我只想知道外援确确实实提高了我们的成绩，提高了我们队伍的国际竞争力了吗？如果没有，那为什么每年花大量人民币让他们来这里养老？羊毛出在羊身上，俱乐部花的钱，还不是从粉丝们身上赚的？联赛与俱乐部背后的资本，从一开始的目的，就不是为了冠军为了成绩，这一切，不过是为了获取背后利益的手段。猪仔们经常拿明凯与同时期国内选手做比较，尤其喜欢拿他与掌门做比较。有时候我其实真的不明白有些人的逻辑，当年掌门变捞的时候被无数黑粉骂，最后他知难而退，选择退役又有何不妥？难道跟明凯一样鼓吹自己的梦想就是好事？当年WE时期，掌门的游走支援与指挥，卷毛微笑的无敌下路，草莓的外站猛如虎，哪一个不比明凯亮眼？WE时期的明凯最值得吹嘘的就是那次比赛强起400了吧？他何曾carry过队伍？WE陨落时，人们津津乐道草莓的300刀，有谁记得明凯的慎吃了他200刀？WE陨落时，若不群背起最大的骂名退役，可笑的是一直没什么存在感的明凯说了一句“我们队里有人混吃等死”后跟着司马布卷毛一起脱离。我一直觉得若风不过是个极度好面子的伪君子罢了，在这个男主播流行黄段子，爆黑料，脏话满天飞的时代，他甚至算得上一股清流。与一直背着虚名，必谈理想却每次都不见长进只会闷头刷野的明凯比，掌门真的好不要太多。猪仔们也喜欢站在道德至高点，花式帮明凯洗白，企图掩盖电竞原罪，经常说国内喷子这么多，厂长怕被喷子喷，怕背黑锅，所以他只是心态不好……我一直怀疑猪仔的智商，对于一个从S2开始一直到现在的老选手来说，还存在这么多心态问题？他当真如此玻璃心？说白了不过时盛名之下其实难副罢了。每次国际比赛，对方打野节奏飞起的时候他在刷，对方打野带蹦三路多路联动的时候他也只能刷了。逆风团战永远不敢开团，哪怕一身肉装。打野思路呆板，永远只会帮中下，永远放弃上单。我真的不知道这到底是菜还是心态差不敢打。猪仔们除了吹嘘明凯的梦想，还喜欢说他谦虚。我真的不知道明凯何时谦虚过。S3全明星的“我要在这个舞台证明谁是世界第一打野”一出，明凯成功依次证明了S3的Insec，S4的Dandy，S5以后就没资格去证明了；S4时期抛弃老队友，lpl常规赛上面对苦苦支撑WE的微笑用猪妹跳舞（别跟我扯嘲讽很正常，联系当时WE的处境，微笑草莓的艰难，他那么做完全是败人品，lpl联赛上让我影响深刻的三大嘲讽：当时还在打中单的姿态，明凯的猪妹，飞行员的虐泉）；今年MSI前还未取得参赛资格时受到采访的那句：我们已经开始研究对手了；今年S6 EDG开赛前采访时被问到外卡打野是他粉丝时的那句：那就一辈子做我的粉丝好了……我真的不知道他被粉丝教做人之后是怎么想的。以上种种，我真的看不出明凯那一点谦虚了，只不过比起直播的高德伟而言不那么跳罢了。猪仔们总喜欢拿明凯的两次世界冠军吹嘘。我真的很想问你们，明凯的两次冠军，是他一个人的吗？又是他carry队伍力挽狂澜所获得的吗？IPL上难道不是吾王与掌门carry的？MSI难道不是胖将军与童无敌carry的？我清楚的记得当时卷毛直播解说决赛的时候，明凯拿出寡妇时卷毛说了一句“eve这英雄，选出来就是MVP”。WE时代的掌门，面瘫，S4时期的U格斯与那逼很美，S5的胖将军，飞行员和扣肉，那个不是内战粗粗的大腿？这里心疼一下扣肉，一个当年被视作短板的选手，终于在EDG的体系下成长起来，一个在MSI上大放异彩的功臣，就这么被俱乐部雪藏，最后为了甩锅给TT这个小解说，美其名曰：效仿SKT双中单体系，打造EDG的双上单体系……这话说的，EDG教练组自己信吗？SKT的双中单，蜗壳与侯爷两个人都是一流选手，那个只会盖伦的港仔也能拿来打造双上单？那为什么S5过后下放他了？不花精力培养？说到底不过是觉得自己能培养一个童无敌就能培养一个石伟豪罢了，最后的结果只能是放弃了一个EDG体系下的优秀上单又忌惮他为他人所用所以索性雪藏。只是为了队伍两次S赛临危背锅，他与EDG也算两不相欠罢了，或许他确实不如明凯有梦想，混吃等死也无所谓。猪仔们又喜欢说，厂长rank无敌，国服大腿，韩服王者……我真的很像知道职业比的是排位分吗？掌门当年被黑的最惨的时候国服第一，国服三大腿之一；笑笑草莓更是早期国服的高玩。影响了他们比赛变捞时所受的质疑了吗？AJ韩服王者这次S6表现如何？扣肉钻石分段死亡轰炸临危背锅他的表现又如何？据说EDG还把韩服排位分作为硬指标，我是真的服。猪仔们还会说，既然EDG与厂长这么垃圾，那lpl别的队伍还不如他们呢？EDG今年16连胜……是的，这一点，你们说的没错，韩援泛滥的今天，lpl的本质就是菜鸡互啄，不管EDG/RNG的国内表现如何，都掩盖不了这一事实。韩援的泛滥，使得俱乐部不再有兴趣花精力培养新人，lpl本质就是菜鸡互啄，所以才有内战猛如虎，外站菜如狗的一次次刷新我们的底线。所以上了国际赛场，lpl队伍的实力暴露的干干净净。内战最凶的EDG，出了国一次次的丢人，从领先一万被湾湾翻盘，与外卡55开，到被欧洲4：0，再到输给外卡，除了证明EDG所代表的lpl越来越垃圾还能证明什么？S4的EDG好歹也是全华班，止步八强也是因为输给同门内战，那时侯的双C也很carry，S赛坑了就踢开引进韩国爹，后来的那逼算是彻底悲剧了，前段时间好不容易常规赛五杀救主，MSI上彻底让他坐定了饮水机，U格斯去了蛇队表现也算不错，后来虽然遗憾退役，最起码证明他基本的实力还是有的。猪仔们喜欢吹嘘的厂长与EDG，反应了lpl赛区的悲哀与菜鸡互啄的本质。明凯四届S赛，年年止步八强，好歹有点长进，要不下次十六强？一次又一次匪夷所思又辣眼睛的表现，对得起他嘴里的梦想吗？电子竞技，菜就是原罪！那些屁股决定脑袋的猪仔就别转移话题了好吗？这篇回答提到多次掌门只不过是因为掌门与明凯同为WE的老队员，一个被捧上天，一个被万人唾弃。说黑点，掌门真的比不上吃鸭脖空大直播间给自己洗白的谢广坤，说人品，掌门真不敢跟你可以草我妈但不能草悠悠的歪特比......掌门再辣鸡，消费的也只是自己的粉丝，明凯消费的却是广大关注比赛的国内玩家！别跟我瞎扯什么明凯比掌门好之类的了，今天明凯能有如此境地，猪仔们功不可没，你们比起当年60e有过之无不及！达不溜意今犹在，不见当年六十亿，南望猪仔又一年，你厂就是不夺冠！我想我已经把自己想表达的说的很清楚了，有些猪仔还是可以曲解，觉得我这么黑明凯是因为我要把锅甩给他一个人。正如我在评论里回复一位朋友的话一样：lpl为了维持泡沫般的繁荣，所以造神，而我就要用黑的方式来还原他们的神。lpl的衰败源于过度的资本化运作，使得联赛失去了健康发展的可能，韩援泛滥，造神运动，都是资本运作的方式。这两点都给选手以及粉丝一种错觉：我们还不错哈，今年是最有希望夺冠的一年，厂长一定能够实现梦想……然而这两点带来错觉的同时，也带来了很大的负面影响，韩援泛滥使得我们不再花精力发掘并培养新人，所以你会觉得新人不能看，这种自废武功的方式我大清都不如；造神运动则是给人一种政治正确：厂长坚持梦想有多努力你知道吗？厂长如果退役了，lpl还有别人吗？对不起，lpl这几年的趋势大家不瞎都能看出来，我们从S2以一个并不算低的起点开始，经历了S3/S4的辉煌，外国赛区在纷纷记住被韩国人支配的恐惧的同时，也记住了实力不俗的lpl赛区，后来我们开始了与外卡五五开，大优势被湾湾翻盘，被欧美轮流掉打，被外卡血虐……一个又一个的笑话，一个又一个的梗。lpl的名额不是明凯帮我们拿到的，lpl再烂都有三个名额，出去都是被掉打，没有什么区别，我不需要这种裤衩都做不了的遮羞布。全华班这种在lpl赛区本应该再正常不过的模式却成了少数人鼓吹情怀恶意营销的资本和黑粉们嘲讽出不了成绩的笑柄，我真的觉得很无奈。韩援泛滥，帮我们赢过几次lck不假，可是没有韩援的湾湾也能做到。选手收入待遇得到飞跃，却越来越不思进取混吃等死，真正出了成绩让人们记住lpl反而是圈内资历较老，待遇很差那个年代的人。联赛俱乐部解说粉丝要神化，别怪我这种黑粉使劲黑，等什么时候这游戏不火了，可能lpl明凯会带着四个韩援夺冠实现梦想吧。]])
	tana:setText([[南京市长春药店]])
	tana:display()
end
dictword=dict:new()
dictword:loadDict([[./uchinese.dict]])
test()



