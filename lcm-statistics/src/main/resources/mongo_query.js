var c = db.executions.find({"execution.processGitPath": {$regex: /\/apps\/(user_filters_brick|users_brick|release_brick|rollout_brick|provisioning_brick)/}, "execution.startTime": {$gt: new Date("05/28/2018").getTime()}});

print("[");
while (c.hasNext()) {
    print(tojson(c.next()));
    print(",");
}
print("]");
