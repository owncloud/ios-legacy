<!--
This is the template for new release issues.
Y <> X
-->

Release a new version
## TASKS:
- [ ] [GIT] Create branch release_X.X.X (freeze the code)
- [ ] [DEV] Update version number X.X.X
- [ ] [DIS] Update changelog iOS app
- [ ] [QA] Design Test plan
- [ ] [QA] Regression Test plan
- [ ] [DIS] Update screenshots if needed
- [ ] [DIS] Release to appstore
- [ ] [DOC] Update user manual https://github.com/owncloud/ios/blob/master/user_manual/ios_app.rst
- [ ] [GIT] Merge branch release_X.X.X in master and develop
- [ ] [GIT] Create tag and sign it "version_X.X.X"

If it is required to update third party or OC iOS Library
- [ ] [DIS] Update THIRD_PARTY.txt

If it is required to update OC iOS Library:
- [ ] [GIT] Create branch library release_Y.Y.Y (freeze the code)
- [ ] [DIS] Update README.md (version number, third party, supported versions of iOS, Xcode)
- [ ] [DIS] Update changelog Doc_Changelog.md 
- [ ] [GIT] Merge branch release_Y.Y.Y in master and develop
- [ ] [GIT] Create tag and sign it "oc-ios-library-Y.Y.Y"


## BUGS & IMPROVEMENTS:

