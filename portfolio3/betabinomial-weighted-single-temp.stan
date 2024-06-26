
data {
  // count and bounds of the data
  // (the same for firstrating, grouprating, and secondrating in this case)
  int N;
  int lb;
  int<lower=lb+1> ub;
  // these 3 are the main data
  vector<lower=lb,upper=ub>[N] FirstRating;  // x1
  vector<lower=lb,upper=ub>[N] GroupRating;  // x2
  array[N] int<lower=lb,upper=ub> SecondRating; // y
}

transformed data {
  array[N] int y;
  // assume participants combine the information by adding two beta
  // distributions beta(y1, ub) and beta(y2, ub) beta(y1+y2, ub+ub) essentially.
  // This is a (fun) property of the beta distribution.
  //
  // Subtract lb because in the end, we want binomial(...) = 0 to correspond to
  // the smallest rating option, ie

  for (i in 1:N) {
    y[i] = SecondRating[i] - lb;
  }
}

parameters {
  real log_inv_temperature;
  real log_weight_mu;
  real log_weight_delta;
}

transformed parameters {
  real<lower=0> inv_temperature = exp(log_inv_temperature);
  real<lower=0> weight1 = exp(log_weight_mu + log_weight_delta/2);
  real<lower=0> weight2 = exp(log_weight_mu - log_weight_delta/2);
  vector[N] shape1;
  vector[N] shape2;
 // how many ..
  shape1 = (FirstRating-lb) * weight1 + (GroupRating-lb) * weight2;
  // out of how many total
  shape2 = rep_vector((ub-lb) * (weight1 + weight2), N);
}

model {
  log_weight_mu    ~ normal(0, 1);
  log_weight_delta ~ normal(0, 1);
  log_inv_temperature ~ normal(0, 1);

  // beta_binomial(shape1, shape2) means binomial(beta(shape1, shape2))
  y ~ beta_binomial(rep_array(ub - lb, N), 1 + shape1 * inv_temperature, 1 + (shape2 - shape1) * inv_temperature);
}

generated quantities {
  vector[N] log_lik;
  array[N] int yrep;

  for (i in 1:N) {
    log_lik[i] = beta_binomial_lpmf(y[i] | ub - lb, 1 + shape1[i] * inv_temperature, 1 + (shape2[i] - shape1[i]) * inv_temperature);
  }

  yrep = beta_binomial_rng(ub - lb, 1 + shape1 * inv_temperature, 1 + (shape2 - shape1) * inv_temperature);
}
