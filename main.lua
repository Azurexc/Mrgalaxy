this file was generate pade luaraph obfuscator v3 Made by galaxy_boy14t#9259

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		for Idx = 1, gBits32() do
			Lines[Idx] = gBits32();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local VIP = 1;
			local Top = -1;
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local function Loop()
				local Instr = Instr;
				local Proto = Proto;
				local Params = Params;
				local _R = _R;
				local Vararg = {};
				local Lupvals = {};
				local Stk = {};
				for Idx = 0, PCount do
					if (Idx >= Params) then
						Vararg[Idx - Params] = Args[Idx + 1];
					else
						Stk[Idx] = Args[Idx + 1];
					end
				end
				local Varargsz = (PCount - Params) + 1;
				local Inst;
				local Enum;
				while true do
					Inst = Instr[VIP];
					Enum = Inst[1];
					if (Enum <= 7) then
						if (Enum <= 3) then
							if (Enum <= 1) then
								if (Enum == 0) then
									Stk[Inst[2]] = Inst[3] ~= 0;
								else
									Stk[Inst[2]] = Env[Inst[3]];
								end
							elseif (Enum == 2) then
								Stk[Inst[2]] = {};
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 5) then
							if (Enum > 4) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							else
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							end
						elseif (Enum == 6) then
							Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						end
					elseif (Enum <= 11) then
						if (Enum <= 9) then
							if (Enum > 8) then
								local A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							else
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum > 10) then
							Stk[Inst[2]]();
						else
							local A = Inst[2];
							Stk[A] = Stk[A]();
						end
					elseif (Enum <= 13) then
						if (Enum > 12) then
							Stk[Inst[2]] = Inst[3];
						else
							do
								return;
							end
						end
					elseif (Enum == 14) then
						Stk[Inst[2]][Inst[3]] = Inst[4];
					else
						local A = Inst[2];
						Stk[A](Stk[A + 1]);
					end
					VIP = VIP + 1;
				end
			end
			A, B = _R(PCall(Loop));
			if not A[1] then
				local line = Chunk[4][VIP] or "?";
				error("Script error at [" .. line .. "]:" .. A[2]);
			else
				return Unpack(A, 2, B);
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
VMCall("LOL!363O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O7470476574033D3O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F73686C6578776172652F4F72696F6E2F6D61696E2F736F75726365030A3O004D616B6557696E646F7703043O004E616D65031A3O004D6164652042792067616C6178795F626F793134742339323539030B3O00486964655072656D69756D0100030A3O0053617665436F6E6669672O01030C3O00436F6E666967466F6C64657203093O004F72696F6E5465737403103O004D616B654E6F74696669636174696F6E03063O0047616C61787903073O00436F6E74656E7403053O00532O6F6E2103053O00496D61676503173O00726278612O73657469643A2O2F2O34382O3334352O393803043O0054696D65026O00144003073O004D616B65546162030A3O005472616465205363616D03043O0049636F6E030B3O005072656D69756D4F6E6C7903093O00412O64546F2O676C65030A3O005363616D20547261646503073O0044656661756C7403083O0043612O6C6261636B030A3O00412O6453656374696F6E03353O00456E61626C6520546865205363616D20547261646520466972737420546F20456E61626C6520546865207472616465207363616D2103073O00537465616C6572030A3O00412O6454657874626F7803083O00557365726E616D65034O00030D3O0054657874446973612O7065617203093O00412O6442752O746F6E03093O00537465616C20506574030C3O0047656D7320537465616C6572030A3O00537465616C2047656D73030B3O00506172746E657220546167030D3O00596F757220557365726E616D6503043O0052616E6B03073O00506172746E657203043O0043686174030C3O005369676E696E67205065742103053O0053656E6421030B3O004D6F6465746F722054616703073O004D6F6465746F7203073O00446973636F7264030C3O004A6F696E20646973636F726403073O004372656469747303083O00412O644C6162656C03113O004A686F6E20436C69666F7264232O322O3600AA3O0012013O00013O001201000100023O00200500010001000300120D000300044O0003000100034O00075O00022O000A3O0001000200200500013O00052O000200033O000400300E00030006000700300E00030008000900300E0003000A000B00300E0003000C000D2O000900010003000200200500023O000E2O000200043O000400300E00040006000F00300E00040010001100300E00040012001300300E0004001400152O00080002000400010020050002000100162O000200043O000300300E00040006001700300E00040018001300300E0004001900092O000900020004000200200500030002001A2O000200053O000300300E00050006001B00300E0005001C000900020600065O0010040005001D00062O000800030005000100200500030002001E2O000200053O000100300E00050006001F2O00090003000500020020050004000100162O000200063O000300300E00060006002000300E00060018001300300E0006001900092O00090004000600020020050005000400212O000200073O000400300E00070006002200300E0007001C002300300E00070024000B000206000800013O0010040007001D00082O00080005000700010020050005000400252O000200073O000200300E000700060026000206000800023O0010040007001D00082O000800050007000100200500050004001E2O000200073O000100300E0007000600272O00090005000700020020050006000400212O000200083O000400300E00080006002200300E0008001C002300300E00080024000B000206000900033O0010040008001D00092O00080006000800010020050006000400252O000200083O000200300E000800060028000206000900043O0010040008001D00092O00080006000800010020050006000100162O000200083O000300300E00080006002900300E00080018001300300E0008001900092O00090006000800020020050007000600212O000200093O000400300E00090006002A00300E0009001C002300300E00090024000B000206000A00053O0010040009001D000A2O00080007000900010020050007000600212O000200093O000400300E00090006002B00300E0009001C002C00300E00090024000B000206000A00063O0010040009001D000A2O00080007000900010020050007000600212O000200093O000400300E00090006002D00300E0009001C002E00300E00090024000B000206000A00073O0010040009001D000A2O00080007000900010020050007000600252O000200093O000200300E00090006002F000206000A00083O0010040009001D000A2O00080007000900010020050007000100162O000200093O000300300E00090006003000300E00090018001300300E0009001900092O00090007000900020020050008000700212O0002000A3O000400300E000A0006002A00300E000A001C002300300E000A0024000B000206000B00093O001004000A001D000B2O00080008000A00010020050008000700212O0002000A3O000400300E000A0006002B00300E000A001C003100300E000A0024000B000206000B000A3O001004000A001D000B2O00080008000A00010020050008000700212O0002000A3O000400300E000A0006002D00300E000A001C002E00300E000A0024000B000206000B000B3O001004000A001D000B2O00080008000A00010020050008000700252O0002000A3O000200300E000A0006002F000206000B000C3O001004000A001D000B2O00080008000A00010020050008000100162O0002000A3O000300300E000A0006003200300E000A0018001300300E000A001900092O00090008000A00020020050009000800252O0002000B3O000200300E000B00060033000206000C000D3O001004000B001D000C2O00080009000B00010020050009000100162O0002000B3O000300300E000B0006003400300E000B0018001300300E000B001900092O00090009000B0002002005000A0009003500120D000C00364O0008000A000C00012O000C3O00013O000E3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O00063O00063O00063O00063O00063O00063O00063O00063O00073O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O000B3O000B3O000B3O000B3O000B3O000B3O000B3O000B3O000C3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763400093O0012013O00013O001201000100023O00200500010001000300120D000300046O000400014O0003000100044O00075O00022O000B3O000100012O000C3O00017O00093O000E3O000E3O000E3O000E3O000E3O000E3O000E3O000E3O000F3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O00123O00123O00123O00123O00123O00123O00123O00123O00133O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763400093O0012013O00013O001201000100023O00200500010001000300120D000300046O000400014O0003000100044O00075O00022O000B3O000100012O000C3O00017O00093O00153O00153O00153O00153O00153O00153O00153O00153O00163O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O00193O00193O00193O00193O00193O00193O00193O00193O001A3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001D3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O001F3O001F3O001F3O001F3O001F3O001F3O001F3O001F3O00203O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763400093O0012013O00013O001201000100023O00200500010001000300120D000300046O000400014O0003000100044O00075O00022O000B3O000100012O000C3O00017O00093O00223O00223O00223O00223O00223O00223O00223O00223O00233O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O00263O00263O00263O00263O00263O00263O00263O00263O00273O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O00293O00293O00293O00293O00293O00293O00293O00293O002A3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763401093O001201000100013O001201000200023O00200500020002000300120D000400046O000500014O0003000200054O000700013O00022O000B0001000100012O000C3O00017O00093O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002D3O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403443O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F73637269707476382F6D61696E2F6175746F6661726D763400093O0012013O00013O001201000100023O00200500010001000300120D000300046O000400014O0003000100044O00075O00022O000B3O000100012O000C3O00017O00093O002F3O002F3O002F3O002F3O002F3O002F3O002F3O002F3O00303O00023O00030C3O00736574636C6970626F617264031D3O00682O7470733A2O2F646973636F72642E2O672F383964676D6A6E46614300043O0012013O00013O00120D000100024O000F3O000200012O000C3O00017O00043O00333O00333O00333O00343O00AA3O00013O00013O00013O00013O00013O00013O00013O00023O00023O00023O00023O00023O00023O00023O00033O00033O00033O00033O00033O00033O00033O00043O00043O00043O00043O00043O00043O00053O00053O00053O00053O00073O00073O00053O00083O00083O00083O00083O00093O00093O00093O00093O00093O00093O000A3O000A3O000A3O000A3O000A3O000C3O000C3O000A3O000D3O000D3O000D3O000F3O000F3O000D3O00103O00103O00103O00103O00113O00113O00113O00113O00113O00133O00133O00113O00143O00143O00143O00163O00163O00143O00173O00173O00173O00173O00173O00173O00183O00183O00183O00183O00183O001A3O001A3O00183O001B3O001B3O001B3O001B3O001B3O001D3O001D3O001B3O001E3O001E3O001E3O001E3O001E3O00203O00203O001E3O00213O00213O00213O00233O00233O00213O00243O00243O00243O00243O00243O00243O00253O00253O00253O00253O00253O00273O00273O00253O00283O00283O00283O00283O00283O002A3O002A3O00283O002B3O002B3O002B3O002B3O002B3O002D3O002D3O002B3O002E3O002E3O002E3O00303O00303O002E3O00313O00313O00313O00313O00313O00313O00323O00323O00323O00343O00343O00323O00353O00353O00353O00353O00353O00353O00363O00363O00363O00363O00", GetFEnv(), ...);
