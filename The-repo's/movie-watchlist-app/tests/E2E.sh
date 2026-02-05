# Get ALB URL
ALB_URL=$(kubectl get ingress -n movie-watchlist -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

echo "Testing: http://$ALB_URL"

#tests
curl -f http://$ALB_URL/health && echo "Health"
curl -f http://$ALB_URL/metrics && echo "Metrics"

curl -X POST http://$ALB_URL/movie/test-1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Movie","genre":"Action","year":2025,"rating":9.0,"watched":true}' && echo "Create"

curl -f http://$ALB_URL/movie/test-1 && echo "Get"
curl -X DELETE -f http://$ALB_URL/movie/test-1 && echo "Delete"

echo "All E2E tests passed!"