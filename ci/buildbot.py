from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException
import pymysql.cursors
import sys
import logging
import time

username="blah-blah"  # <<<------ Put your username here
password="blah-blah" # <<<------- Put your password here
driver = webdriver.Chrome('/usr/bin/chromedriver')
driver.get("https://{}:{}@buildbot.sh.intel.com".format(username,password))
driver.maximize_window()

#builders

builders=['master-latest']

connection = pymysql.connect(host='localhost',user='root',password='',db='buildbot',charset='utf8mb4',cursorclass=pymysql.cursors.DictCursor)

for builder in builders:
	started = False
	ended = False
	i = 1
	watchdog=0
	while not ended:
		url = "https://buildbot.com/absp/builders/{}/builds/{}".format(builder,i)
		results = {
			'Start' : '',
			'End' : ''
		}
		print(url)
		i=i+1

		#Check if we have already visited this build
		count=0
		with connection.cursor() as cursor:
			sql = "select * from build_info where builder=%s and buildId=%s"
			count = cursor.execute(sql,(builder,i-1))
		if count is 1:
			print("Skipped")
			started=True
			continue

		time.sleep(1) #sleep for 1-second - be polite :)

		try:
			driver.get(url)
		except TimeoutException as e:
			print("TIMEOUT EXCEPTION",e)

		#check if 404 error occured
		if watchdog >= 15:
			break
		if "No Such Resource" in driver.title:
			if started:
				ended=True
			watchdog = watchdog+1
			continue;

		started=True
		try:
			#Fetch all the buildInfo
			for item in driver.find_elements_by_xpath('.//*[@id="buildinfo"]/div/table/tbody/tr[*]'):
				results[item.find_element_by_xpath('.//td[1]').get_attribute('innerText')] = item.find_element_by_xpath('.//td[2]').get_attribute('innerText')

			#Fetch all the build properties
			for item in driver.find_elements_by_xpath('.//*[@id="buildprops"]/div[1]/table/tbody/tr[position()>1]'):
				results[item.find_element_by_xpath('.//td[1]').get_attribute('innerText')] = item.find_element_by_xpath('.//td[2]').get_attribute('innerText')

			#Fetch all the forced build properties
			for item in driver.find_elements_by_xpath('.//*[@id="buildprops"]/div[2]/table/tbody/tr[position()>1]'):
				results[item.find_element_by_xpath('.//td[1]').get_attribute('innerText')] = item.find_element_by_xpath('.//td[3]').get_attribute('innerText')

			#fetch the result
			result = driver.find_element_by_xpath('.//*[@class="col-sm-4"]//p[1]').get_attribute('innerText')
			if "successful" in result.lower():
				status='1'
			elif "fail" in result.lower():
				status='0'
			elif "cancel" in result.lower():
				status='2'
			elif "exception" in result.lower():
				status='3'
			else:
				status=''

			with connection.cursor() as cursor:
				sql = 'insert into build_info(builder,buildId,startedAt,endedAt,elapsed,status) values (%s,%s,%s,%s,%s,%s)'
				cursor.execute(sql,(builder,i-1,results['Start'],results['End'],results['Elapsed'],status))

				sql = 'insert into build_properties(builder,buildId,artOutputUrl,availableProducts,branch,branchName,bugFields,bugs,builderName,buildNumber,buildVariant,domains,checkExternal,explicitRepoDownloads,failIfTooManyWarnings,majorVersion,manifest,manifestBranch,maxWarnCount,owners,project,referenceBuild,repoDownloads,repoDownloadsPerManifest,repoType,repository,revision,shortBuildNumber,slaveName,startedAt,status,variant,workdir) values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)'
				cursor.execute(sql,(builder,i-1,results['artOutputURL'],results['available_products'],results['branch'],results['branch_name'],results['bug_fields'],results['bugs'],results['buildername'],results['buildnumber'],results['buildvariant'],results['domains'],results['check_external'],results['explicit_repo_downloads'],results['fail_if_too_many_warning'],results['major_version'],results['manifest'],results['manifest_branch'],results['max_warn_count'],results['owners'],results['project'],results['reference_build'],results['repo_downloads'],results['repo_downloads_per_manifests'],results['repo_type'],results['repository'],results['revision'],results['short_build_number'],results['slavename'],results['started_at'],results['status'],results['variant'],results['workdir']))

				sql = 'insert into forced_build_properties(builder,buildId,additionalBuildFlags,additionalTests,branchList,cherryPickFromOtherGerrit,customizedBuildCommand,downloadListComputationMode,externalTestChecked,forceBuildChangeIDs,forceScheduler,manifestOverrideUrl,owner,preferredSite,reason,targetProductsToBuild,testedBoardProducts,variantList) values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)'
				cursor.execute(sql,(builder,i-1,results['additional_build_flags'],results['additionnal_tests'],results['branch_list'],results['cherry_pick_from_other_gerrit'],results['customized_build_command'],results['download_list_computation_mode'],results['external_test_checked'],results['force_build_changeids'],results['forcescheduler'],results['manifest_override_url'],results['owner'],results['preferred_site'],results['reason'],results['target_products_to_build'],results['tested_board_products'],results['variant_list']))

				connection.commit()
		except NoSuchElementException as e:
			print("NO SUCH ELEMENT EXCEPTION!!!",e)
		except Exception as e:
			print("********** Exception occured ***********")
			print(e)

connection.close()
