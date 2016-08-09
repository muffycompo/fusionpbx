--	Part of FusionPBX
--	Copyright (C) 2013-2015 Mark J Crane <markjcrane@fusionpbx.com>
--	All rights reserved.
--
--	Redistribution and use in source and binary forms, with or without
--	modification, are permitted provided that the following conditions are met:
--
--	1. Redistributions of source code must retain the above copyright notice,
--	  this list of conditions and the following disclaimer.
--
--	2. Redistributions in binary form must reproduce the above copyright
--	  notice, this list of conditions and the following disclaimer in the
--	  documentation and/or other materials provided with the distribution.
--
--	THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
--	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
--	AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--	AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
--	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
--	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
--	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
--	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--	POSSIBILITY OF SUCH DAMAGE.

--voicemail count if zero new messages set the mwi to no
	function message_waiting(voicemail_id, domain_uuid)
		--initialize the array and add the voicemail_id
		 	local accounts = {}
			table.insert(accounts, voicemail_id);
		--get the voicemail id and all related mwi accounts
			local sql = [[SELECT extension, number_alias from v_extensions
				WHERE domain_uuid = ']] .. domain_uuid ..[['
				AND (mwi_account = ']]..voicemail_id..[[' or mwi_account = ']]..voicemail_id..[[@]]..domain_name..[[')]];
			if (debug["sql"]) then
				freeswitch.consoleLog("notice", "[voicemail] SQL: " .. sql .. "\n");
			end
			dbh:query(sql, function(row)
				if (string.len(row["number_alias"]) > 0) then
					table.insert(accounts, row["number_alias"]);
				else
					table.insert(accounts, row["extension"]);
				end
			end);

		--get new and saved message counts
			local new_messages, saved_messages = message_count_by_id(
				voicemail_id, domain_uuid
			)

		--send the message waiting event
			for _,value in ipairs(accounts) do
				local account = value.."@"..domain_name
				mwi_notify(account, new_messages, saved_messages)
				if (debug["info"]) then
					if new_messages == "0" then
						freeswitch.consoleLog("notice", "[voicemail] mailbox: "..account.." messages: no new messages\n");
					else
						freeswitch.consoleLog("notice", "[voicemail] mailbox: "..account.." messages: " .. new_messages .. " new message(s)\n");
					end
				end
			end
	end
