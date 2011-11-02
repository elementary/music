def add_info(report):
    try:
        if not apport.packaging.is_distro_package(report['Package'].split()[0]):
			report['ThirdParty'] = 'True'
			report['CrashDB'] = 'beatbox'
    except ValueError, e:
        return
