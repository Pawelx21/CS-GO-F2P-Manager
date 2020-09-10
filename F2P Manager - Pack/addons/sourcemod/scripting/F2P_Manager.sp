/* [ Includes ] */
#include <sourcemod>
#include <sdktools>
#include <SteamWorks>
#include <multicolors>

/* [ Compiler Options ] */
#pragma newdecls required
#pragma semicolon	1

/* [ Defines ] */
#define MaxCvars		6
#define KeyValue		"F2P Manager - Config"
#define PluginTag_Info	"★ {lightred}[ F2P Manager ]{default}"

/* [ Chars ] */
char g_sCvInfo[MaxCvars][3][256] =  {
	{ "csgo_hours", "1700", "Liczba godzin, którą musi posiadać gracz, żeby wejść na serwer." }, 
	{ "csgo_level", "5", "Minimalny poziom, którą musi posiadać gracz, żeby wejść na serwer." }, 
	{ "csgo_pin", "1", "Czy gracz musi posiadać odznakę, żeby wejść na serwer." }, 
	{ "requirements", "4", "Które warunki mają być spełnione, żeby wpuścić gracza na serwer. 1 - Godziny | 2 - Godziny + Poziom | 3 - Godziny + Poziom + Odznaka | 4 - Poziom | 5 - Poziom + Odznaka | 6 - Odznaka | 7 - Obojętnie" }, 
	{ "vip_pass", "1", "Czy gracze ze statusem VIP mają omijać zabezpieczenia? 1 - Tak | 0 - Nie" }, 
	{ "api_key", "xxxxxxxxxxxx", "Klucz potrzebny do sprawdzenia godzin. (https://steamcommunity.com/dev/apikey)" }
};
char g_sApiKey[128];

/* [ Integers ] */
int g_iTime[MAXPLAYERS + 1];
int g_iCvar[5];

/* [ Plugin Author and Informations ] */
public Plugin myinfo =  {
	name = "[CS:GO] Pawel - [ F2P Manager ]", 
	author = "Pawel", 
	description = "Kilka zabezpieczeń przed potencjalnymi cheaterami z nowymi kontami.", 
	version = "2.0", 
	url = "https://go-code.pl/"
};

/* [ Plugin Startup ] */
public void OnPluginStart() {
	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Pre);
	CreateTimer(360.0, Timer_AuthorInfo, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/* [ Standard Actions ] */
public void OnMapStart() {
	LoadConfig();
}

public void OnClientPutInServer(int client) {
	if (IsValidClient(client))
		Reset(client);
}

/* [ Events ] */
public Action Event_PlayerConnectFull(Event event, const char[] sName, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client)) {
		Handle hRequest = CreateRequest_TimePlayed(client);
		SteamWorks_SendHTTPRequest(hRequest);
	}
}

/* [ Helpers ] */
void SecurityCheck(int client) {
	char sBuffer[1024];
	Format(sBuffer, sizeof(sBuffer), "» F2P Manager by Paweł");
	
	bool bKick = false;
	int resource_entity = GetPlayerResourceEntity();
	int level = GetEntProp(resource_entity, Prop_Send, "m_nPersonaDataPublicLevel", _, client);
	int coin = GetEntProp(resource_entity, Prop_Send, "m_nActiveCoinRank", _, client);
	switch (g_iCvar[3]) {
		case 1: {
			if (g_iTime[client] < g_iCvar[0]) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Mieć przegrane minimum %d godzin w CS:GO  %s", sBuffer, g_iCvar[0], g_iTime[client] >= g_iCvar[0] ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 2: {
			if (g_iTime[client] < g_iCvar[0] && level < g_iCvar[1]) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Mieć przegrane minimum %d godzin w CS:GO  %s", sBuffer, g_iCvar[0], g_iTime[client] >= g_iCvar[0] ? "[✓]":"[X]");
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać minimum %d lvl w CS:GO  %s", sBuffer, g_iCvar[1], level >= g_iCvar[1] ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 3: {
			if (g_iTime[client] < g_iCvar[0] || level < g_iCvar[1] || coin == 0) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Mieć przegrane minimum %d godzin w CS:GO  %s", sBuffer, g_iCvar[0], g_iTime[client] >= g_iCvar[0] ? "[✓]":"[X]");
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać minimum %d lvl w CS:GO  %s", sBuffer, g_iCvar[1], level >= g_iCvar[1] ? "[✓]":"[X]");
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać jakąkolwiek odznakę  %s", sBuffer, coin != 0 ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 4: {
			if (level < g_iCvar[1]) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać minimum %d lvl w CS:GO  %s", sBuffer, g_iCvar[1], level >= g_iCvar[1] ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 5: {
			if (level < g_iCvar[1] && coin == 0) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać minimum %d lvl w CS:GO  %s", sBuffer, g_iCvar[1], level >= g_iCvar[1] ? "[✓]":"[X]");
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać jakąkolwiek odznakę  %s", sBuffer, coin != 0 ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 6: {
			if (coin == 0) {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać następujace wymagania:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać jakąkolwiek odznakę  %s", sBuffer, coin != 0 ? "[✓]":"[X]");
				bKick = true;
			}
		}
		case 7: {
			if (g_iTime[client] >= g_iCvar[0] || level >= g_iCvar[1] || coin != 0)
				bKick = false;
			else {
				Format(sBuffer, sizeof(sBuffer), "%s\n» Aby wejść na serwer musisz spełniać jedno z poniższych wymagań:", sBuffer);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Mieć przegrane minimum %d godzin w CS:GO", sBuffer, g_iCvar[0]);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać minimum %d lvl w CS:GO", sBuffer, g_iCvar[1]);
				Format(sBuffer, sizeof(sBuffer), "%s\n» Posiadać jakąkolwiek odznakę", sBuffer);
				bKick = true;
			}
		}
	}
	if (bKick) {
		KickClient(client, sBuffer);
		return;
	}
	PrintToChatAll("%d", level);
}

Handle CreateRequest_TimePlayed(int client) {
	char sRequest[256], sAuthId[64];
	GetClientAuthId(client, AuthId_SteamID64, sAuthId, sizeof(sAuthId));
	Format(sRequest, sizeof(sRequest), "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=%s&appids_filter[0]=730&steamid=%s&format=json", g_sApiKey, sAuthId);
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
	
	SteamWorks_SetHTTPRequestContextValue(hRequest, client);
	SteamWorks_SetHTTPCallbacks(hRequest, TimePlayed_OnHTTPResponse);
	return hRequest;
}

public int TimePlayed_OnHTTPResponse(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client) {
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK) {
		delete hRequest;
		return;
	}
	
	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(hRequest, iBufferSize);
	
	char[] sBuffer = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBuffer, iBufferSize);
	
	int hours = GetClientHours(sBuffer) / 60;
	if (hours <= 0) {
		char sInfo[256];
		Format(sInfo, sizeof(sInfo), "» F2P Manager by Paweł");
		Format(sInfo, sizeof(sInfo), "%s\n» Aby wejśc na serwer musisz mieć profil publiczny", sInfo);
		Format(sInfo, sizeof(sInfo), "%s\n» Steam ➪ Edytuj Profil ➪ Ustawienia Prywatności ➪", sInfo);
		Format(sInfo, sizeof(sInfo), "%s\n» Widoczność mojego profilu: Publiczna", sInfo);
		Format(sInfo, sizeof(sInfo), "%s\n» Widoczność szczegółów gry: Publiczna + odznaczona opcja pod tym", sInfo);
		KickClient(client, sInfo);
	}
	g_iTime[client] = hours;
	if (k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820)) {
		if (g_iCvar[4] == 1 && !IsPlayerVip(client))
			SecurityCheck(client);
		else if (g_iCvar[4] == 0)
			SecurityCheck(client);
	}
	delete hRequest;
}

bool IsValidClient(int client) {
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}

bool IsPlayerVip(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)return true;
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)return true;
	return false;
}

int GetClientHours(char[] sBuffer) {
	char sString[8][64], sString2[2][32];
	ExplodeString(sBuffer, ",", sString, sizeof(sString), sizeof(sString[]));
	for (int i = 0; i < 8; i++) {
		if (StrContains(sString[i], "playtime_forever") != -1) {
			ExplodeString(sString[i], ":", sString2, sizeof(sString2), sizeof(sString2[]));
			int hours = StringToInt(sString2[1]);
			return hours;
		}
	}
	return -1;
}

void Reset(int client) {
	g_iTime[client] = 0;
}

/* [ Config ] */
void LoadConfig() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/F2P_Manager.cfg");
	KeyValues kv = new KeyValues(KeyValue);
	if (!kv.ImportFromFile(sPath))
		if (!FileExists(sPath)) {
		GenerateConfig();
		delete kv;
	}
	
	g_iCvar[0] = kv.GetNum(g_sCvInfo[0][0]);
	g_iCvar[1] = kv.GetNum(g_sCvInfo[1][0]);
	g_iCvar[2] = kv.GetNum(g_sCvInfo[2][0]);
	g_iCvar[3] = kv.GetNum(g_sCvInfo[3][0]);
	g_iCvar[4] = kv.GetNum(g_sCvInfo[4][0]);
	kv.GetString(g_sCvInfo[5][0], g_sApiKey, sizeof(g_sApiKey));
	delete kv;
}

void GenerateConfig() {
	char sPath[PLATFORM_MAX_PATH], sBuffer[1024];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/F2P_Manager.cfg");
	File fFile = OpenFile(sPath, "a");
	Format(sBuffer, sizeof(sBuffer), "\"%s\"", KeyValue);
	fFile.WriteLine(sBuffer);
	fFile.WriteLine("{");
	for (int i = 0; i < sizeof(g_sCvInfo); i++) {
		Format(sBuffer, sizeof(sBuffer), "	\"%s\"		\"%s\"		// %s", g_sCvInfo[i][0], g_sCvInfo[i][1], g_sCvInfo[i][2]);
		fFile.WriteLine(sBuffer);
	}
	fFile.WriteLine("}");
	delete fFile;
	LoadConfig();
}

/* [ Timers ] */
public Action Timer_AuthorInfo(Handle timer) {
	CPrintToChatAll("%s Plugin został napisany przez {lime}Pawła{default}.", PluginTag_Info);
	CPrintToChatAll("%s Plugin jest udostepniony za darmo na {lime}Go-Code.pl{default}.", PluginTag_Info);
} 